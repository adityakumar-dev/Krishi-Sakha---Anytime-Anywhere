# brain/model_run.py

from brain.brain_init import default_model, voice_model, vision_model
from configs.model_config import CROP_ADVISE_SYSTEM_MESSAGE, DEFAULT_SYSTEM_MESSAGE, VOICE_SYSTEM_MESSAGE
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser
from langchain_core.messages import HumanMessage, SystemMessage
import logging
import base64
from datetime import datetime
from typing import Any, AsyncGenerator, Dict, Optional, List
import google.generativeai as genai
from configs.external_keys import GEMINI_API_KEY

from routes.helpers.push_supabase import push_to_supabase

logger = logging.getLogger(__name__)

# Configure Gemini API
genai.configure(api_key=GEMINI_API_KEY)
gemini_model = genai.GenerativeModel('gemini-2.0-flash')

class ModelRun:
    def __init__(self):
        self.default_model = default_model
        self.voice_model = voice_model
        self.vision_model = vision_model

        self.rag_template = ChatPromptTemplate.from_messages([
            ("system", DEFAULT_SYSTEM_MESSAGE + "\n\nUse the following context to answer the user's question:\n{context}"),
            ("human", "{question}")
        ])
        self.voice_template = ChatPromptTemplate.from_messages([
            ("system", VOICE_SYSTEM_MESSAGE),
            ("human", "{question}") 
        ])
        self.general_template = ChatPromptTemplate.from_messages([
            ("system", DEFAULT_SYSTEM_MESSAGE),
            ("human", "{question}")
        ])

    async def generate(
        self,
        question: str,
        context: str = "",
        conversation_id: str = "",
        user_id: str = "",
        use_voice_model: bool = False,
        stream: bool = True,
        push_to_db: bool = True,
        metadata: Optional[Dict[str, List[str]]] = None,
        history: Optional[List[Dict[str, str]]] = None
    ) -> AsyncGenerator[str, None]:

        # Dynamically build prompt with history
        messages = []
        if context:
            messages.append(("system", DEFAULT_SYSTEM_MESSAGE + "\n\nUse the following context to answer the user's question:\n{context}"))
        else:
            messages.append(("system", DEFAULT_SYSTEM_MESSAGE))

        # Insert previous chat history if provided
        if history:
            for turn in history:
                role = turn.get("role")
                content = turn.get("content", "")
                if role == "user":
                    messages.append(("human", content))
                elif role == "assistant":
                    messages.append(("ai", content))

        # Add the current question
        messages.append(("human", "{question}"))

        template = ChatPromptTemplate.from_messages(messages)
        model    = self.voice_model if use_voice_model else self.default_model
        chain    = template | model | StrOutputParser()

        chain_input = {"question": question}
        if context:
            chain_input["context"] = context

        full_response = ""

        if stream:
            async for chunk in chain.astream(chain_input):
                if chunk:
                    full_response += chunk
                    yield chunk
        else:
            full_response = await chain.ainvoke(chain_input)
            yield full_response

        # log only once at end
        if push_to_db:
            push_to_supabase(
                'chat_messages',
                {
                    'conversation_id': conversation_id,
                    'user_id': user_id,
                    'message': full_response,
                    'sender' : "assistant",
                    'metadata' : metadata
            }
        )

    async def generate_image(
        self,
        question: str,
        conversation_id: str = "",
        user_id: str = "",
        image_path: str = "",
        history: Optional[List[Dict[str, str]]] = None,
        stream: bool = True
    ) -> AsyncGenerator[str, None]:

        if image_path == "":
            raise ValueError("generate_image() requires image_path != None")

        pushed = False
        try:
            logger.info(f"Reading image from: {image_path}")
            with open(image_path, "rb") as f:
                image_bytes = f.read()
            logger.info(f"Image size: {len(image_bytes)} bytes")
            image_b64 = base64.b64encode(image_bytes).decode("utf-8")
            data_url = f"data:image/jpeg;base64,{image_b64}"
            logger.info(f"Question: {question}")
            logger.info(f"Data URL length: {len(data_url)}")

            # Build message list with history
            message_content = []
            if history:
                for turn in history:
                    role = turn.get("role")
                    content = turn.get("content", "")
                    if role == "user":
                        message_content.append({"type": "text", "text": content})
                    elif role == "assistant":
                        message_content.append({"type": "text", "text": content})
            # Add current question and image
            message_content.append({"type": "text", "text": question})
            message_content.append({"type": "image_url", "image_url": {"url": data_url}})

            message = HumanMessage(content=message_content)
            logger.info("HumanMessage created successfully")
            logger.info("Starting model streaming...")
            full_response = ""
            if stream:
                chunk_count = 0
                async for chunk in self.vision_model.astream([message]):
                    chunk_count += 1
                    logger.info(f"Received chunk {chunk_count}: {type(chunk)}")
                    if chunk and hasattr(chunk, 'content') and chunk.content:
                        content = chunk.content
                        logger.info(f"Chunk content: {content[:100]}...")
                        full_response += content
                        yield content
                    elif isinstance(chunk, str):
                        logger.info(f"String chunk: {chunk[:100]}...")
                        full_response += chunk
                        yield chunk
                    else:
                        logger.info(f"Unknown chunk type: {chunk}")
                logger.info(f"Streaming completed. Total chunks: {chunk_count}, Response length: {len(full_response)}")
            else:
                logger.info("Using non-streaming mode...")
                response = await self.vision_model.ainvoke([message])
                logger.info(f"Response type: {type(response)}")
                content = response.content if hasattr(response, 'content') else str(response)
                full_response = content
                yield content
            if full_response:
                push_to_supabase(
                    'chat_messages',
                    {
                        'conversation_id': conversation_id,
                        'user_id': user_id,
                        'message': full_response,
                        'sender': "assistant",
                    }
                )
                pushed = True
        except Exception as e:
            logger.error(f"Error in generate_image: {str(e)}")
            error_msg = f"Sorry, I encountered an error processing the image: {str(e)}"
            yield error_msg
            if not pushed:
                push_to_supabase(
                    'chat_messages',
                    {
                        'conversation_id': conversation_id,
                        'user_id': user_id,
                        'message': error_msg,
                        'sender': "assistant",
                    }
                )
    async def generate_voice(
        self,
        question: str,
    ) -> AsyncGenerator[str, None]:

        template = self.voice_template
        model    = self.voice_model
        chain    = template | model | StrOutputParser()

        chain_input = {"question": question}

        async for chunk in chain.astream(chain_input):
                if chunk:
                    yield chunk

    async def run_rag(self, question: str, context: str) -> AsyncGenerator[str, None]:

        template = self.rag_template
        model    = self.default_model
        chain    = template | model | StrOutputParser()

        chain_input = {"question": question, "context": context}

        async for chunk in chain.astream(chain_input):
            if chunk:
                yield chunk

    async def run_pipeline(
        self,
        question: str,
        pipeline_context: Dict[str, Any],
        conversation_id: str = "",
        user_id: str = "",
        stream: bool = True,
        push_to_db: bool = True
    ) -> AsyncGenerator[str, None]:
        """
        Run model with context from complete pipeline (vector DB, weather, schemes, prices, etc.)
        
        Args:
            question: Farmer's original question
            pipeline_context: Dict containing all retrieved contexts from pipeline
            conversation_id: Conversation ID for tracking
            user_id: User ID
            stream: Whether to stream response
            push_to_db: Whether to save to database
            
        Yields:
            Response chunks
        """
        from configs.model_config import PIPELINE_SYSTEM_MESSAGE
        
        # Build comprehensive context string from all sources
        context_parts = []
        
        # Vector DB context
        if pipeline_context.get('vector_db'):
            vdb = pipeline_context['vector_db']
            if vdb.get('success') and vdb.get('context'):
                context_parts.append("📚 AGRICULTURAL KNOWLEDGE BASE:")
                for i, doc in enumerate(vdb['context'][:3], 1):  # Top 3 docs
                    context_parts.append(f"\n[Document {i}] {doc.get('metadata', {}).get('source_file', 'Unknown source')}")
                    context_parts.append(f"Pages {doc.get('metadata', {}).get('start_page')}-{doc.get('metadata', {}).get('end_page')}")
                    context_parts.append(doc['text'][:1000])  # Limit length
        
        # Weather context
        if pipeline_context.get('weather'):
            weather = pipeline_context['weather']
            if weather.get('success') and weather.get('context'):
                wc = weather['context']
                context_parts.append(f"\n\n🌤️ WEATHER FORECAST ({wc['station_name']}):")
                context_parts.append(f"Sunrise: {wc['sun_timings']['sunrise']} | Sunset: {wc['sun_timings']['sunset']}")
                for day in wc['forecast'][:3]:  # Next 3 days
                    context_parts.append(f"\n{day['date']}: {day['description']}")
                    context_parts.append(f"Temp: {day['min_temp']}°C - {day['max_temp']}°C, Humidity: {day['humidity_morning']}%-{day['humidity_evening']}%")
                    if day['warning'] != 'No warning':
                        context_parts.append(f"⚠️ {day['warning']}")
        
        # Government schemes
        if pipeline_context.get('schemes'):
            schemes = pipeline_context['schemes']
            if schemes.get('success') and schemes.get('context', {}).get('schemes'):
                context_parts.append(f"\n\n🏛️ GOVERNMENT SCHEMES ({schemes.get('state', 'Kerala')}):")
                for i, scheme in enumerate(schemes['context']['schemes'][:5], 1):  # Top 5 schemes
                    context_parts.append(f"\n{i}. {scheme['name']} ({scheme['level']})")
                    context_parts.append(f"   Ministry: {scheme['ministry']}")
                    context_parts.append(f"   {scheme['description'][:200]}...")
                    context_parts.append(f"   URL: {scheme['url']}")
        
        # Market prices
        if pipeline_context.get('prices'):
            prices = pipeline_context['prices']
            if prices.get('success') and prices.get('context', {}).get('prices'):
                context_parts.append(f"\n\n🌾 MANDI PRICES ({prices.get('state', 'KERALA')}):")
                for i, price in enumerate(prices['context']['prices'][:10], 1):  # Top 10 commodities
                    context_parts.append(f"\n{i}. {price['commodity']} ({price['variety']})")
                    context_parts.append(f"   APMC: {price['apmc']}, {price['district']}")
                    context_parts.append(f"   Price: ₹{price['min_price']}-₹{price['max_price']}/{price['unit']} (Modal: ₹{price['modal_price']})")
        
        # Note: YouTube videos are not included in model context - they're for frontend display only
        
        # Web search results
        if pipeline_context.get('web_search'):
            web = pipeline_context['web_search']
            if web.get('success'):
                if web.get('context', {}).get('pages'):  # Scraped content available
                    context_parts.append(f"\n\n🔍 WEB INFORMATION:")
                    for i, page in enumerate(web['context']['pages'][:3], 1):  # Top 3 pages
                        if page.get('content'):
                            context_parts.append(f"\n{i}. {page['title']}")
                            context_parts.append(f"   Source: {page['url'][:80]}...")
                            context_parts.append(f"   {page['content'][:500]}...")
                elif web.get('context', {}).get('urls'):
                    context_parts.append(f"\n\n🔗 RELEVANT URLS:")
                    for i, url in enumerate(web['context']['urls'][:5], 1):
                        context_parts.append(f"{i}. {url}")
        
        combined_context = "\n".join(context_parts)
        
        # Build prompt with system message and context
        messages = [
            ("system", PIPELINE_SYSTEM_MESSAGE + "\n\nUSE THE FOLLOWING CONTEXT TO ANSWER:\n{context}"),
            ("human", "{question}")
        ]
        
        template = ChatPromptTemplate.from_messages(messages)
        chain = template | self.default_model | StrOutputParser()
        
        chain_input = {
            "question": question,
            "context": combined_context
        }
        
        full_response = ""
        
        if stream:
            async for chunk in chain.astream(chain_input):
                if chunk:
                    full_response += chunk
                    yield chunk
        else:
            full_response = await chain.ainvoke(chain_input)
            yield full_response
        
        # Save to database
        if push_to_db and full_response:
            push_to_supabase(
                'chat_messages',
                {
                    'conversation_id': conversation_id,
                    'user_id': user_id,
                    'message': full_response,
                    'sender': 'assistant',
                    'metadata': {
                        'sources': list(pipeline_context.keys()),
                        'context_types': [k for k, v in pipeline_context.items() if v.get('success')]
                    }
                }
            )
    

model_runner = ModelRun()