from fastapi import APIRouter, UploadFile, File, Form, Depends
from fastapi.responses import StreamingResponse
from typing import Optional
import json
import logging
import os

from routes.middlewares.auth_middleware import supabase_jwt_middleware
from brain.model_run import model_runner
from routes.helpers.push_supabase import push_to_supabase
from brain.pipeline import (
    process_farmer_query,
    get_vector_db_context,
    get_imd_weather_context,
    get_myscheme_context,
    get_enam_price_context,
    get_youtube_context,
    get_web_search_context
)

logger = logging.getLogger(__name__)
router = APIRouter()


@router.post("/chat/agri")
async def chat_agri(
    prompt: str = Form(...),
    conversation_id: str = Form(...),
    image: Optional[UploadFile] = File(None),
    history: str = Form(None),
    state: str = Form(None),  # User's preferred state
    station_id: str = Form(None),  # User's preferred weather station
    user=Depends(supabase_jwt_middleware)
):
    """
    Agricultural chat endpoint with full pipeline support
    Handles text queries with context retrieval from multiple sources
    Also supports image-based queries
    
    Args:
        state: User's state preference (e.g., 'Kerala', 'Tamil Nadu')
        station_id: User's preferred IMD weather station ID (e.g., '99952')
    """
    user_id = user.get("sub")
    logger.info(f"User: {user_id}, Conversation: {conversation_id}, Query: {prompt[:100]}, State: {state}, Station: {station_id}")
    
    # Parse history if provided
    parsed_history = None
    last_response = ""
    if history:
        try:
            parsed_history = json.loads(history)
            # Extract last assistant message for context
            if parsed_history and isinstance(parsed_history, list):
                for msg in reversed(parsed_history):
                    if msg.get('sender') == 'assistant':
                        last_response = msg.get('message', '')
                        break
        except Exception as e:
            logger.warning(f"Failed to parse history: {e}")
    
    # Read image bytes if provided
    image_bytes = None
    if image:
        image_bytes = await image.read()
        logger.info(f"Read {len(image_bytes)} bytes from image")

    async def event_stream():
        try:
            # ---------------------------------------------------------------------
            # IMAGE REQUEST
            # ---------------------------------------------------------------------
            if image_bytes:
                yield f"data: {json.dumps({'type': 'status', 'message': 'Processing uploaded image...'})}\n\n"

                temp_dir = "./temp"
                os.makedirs(temp_dir, exist_ok=True)
                
                file_extension = image.filename.split('.')[-1] if image.filename and '.' in image.filename else 'jpg'
                image_path = f"{temp_dir}/image_{conversation_id}.{file_extension}"

                try:
                    with open(image_path, "wb") as f:
                        f.write(image_bytes)
                    logger.info(f"Saved temp image to {image_path}")

                    final_query = prompt if prompt.strip() else "What do you see in this image?"

                    async for chunk in model_runner.generate_image(
                        question=final_query,
                        conversation_id=conversation_id,
                        user_id=user_id,
                        image_path=image_path,
                        stream=True,
                    ):
                        yield f"data: {json.dumps({'type': 'text', 'chunk': chunk})}\n\n"

                    yield "data: {\"type\": \"complete\"}\n\n"

                except Exception as image_error:
                    logger.error(f"Error processing image: {str(image_error)}")
                    yield f"data: {json.dumps({'type': 'error', 'message': f'Error processing image: {str(image_error)}'})}\n\n"

                finally:
                    try:
                        if os.path.exists(image_path):
                            os.remove(image_path)
                            logger.info("Temp image removed")
                    except Exception as cleanup_err:
                        logger.warning(f"Failed to cleanup temp image: {cleanup_err}")

                return

            # ---------------------------------------------------------------------
            # TEXT-ONLY REQUEST - PIPELINE EXECUTION
            # ---------------------------------------------------------------------
            yield f"data: {json.dumps({'type': 'status', 'message': 'Processing query...'})}\n\n"
            
            # Step 1: Process query with Gemini (with conversation context)
            yield f"data: {json.dumps({'type': 'status', 'message': 'Analyzing query...'})}\n\n"
            processed = process_farmer_query(prompt, last_response=last_response)
            
            actions = processed.get('actions', [])
            is_general = processed.get('is_general', False)
            # Use user preference state, or fall back to processed query state, or default to Kerala
            state_name = state or processed.get('state_name', 'Kerala')
            optimized_query = processed.get('optimized_query', prompt)
            
            logger.info(f"Processed query: actions={actions}, is_general={is_general}, state={state_name} (user_pref={bool(state)})")
            
            # Check if query should be generated
            if not processed.get('generate', True):
                rejection_message = "I'm specifically designed to help with agricultural queries. Please ask me about farming, crops, weather, prices, or government schemes."
                yield f"data: {json.dumps({'type': 'text', 'chunk': rejection_message})}\n\n"
                yield f"data: {json.dumps({'type': 'complete'})}\n\n"
                return
            
            # Step 2: Fetch contexts based on actions
            pipeline_context = {}
            youtube_results = []
            web_urls = []
            
            # Vector DB context
            if 'vector_db' in actions:
                yield f"data: {json.dumps({'type': 'status', 'message': 'Searching knowledge base...'})}\n\n"
                vdb_result = get_vector_db_context(optimized_query, n_results=3)
                pipeline_context['vector_db'] = vdb_result
                logger.info(f"Vector DB: {vdb_result.get('results_count', 0)} documents")
            
            # Weather context
            if 'imd' in actions:
                yield f"data: {json.dumps({'type': 'status', 'message': 'Fetching weather forecast...'})}\n\n"
                weather_result = get_imd_weather_context(state_name=state_name)
                pipeline_context['weather'] = weather_result
                logger.info(f"Weather: {weather_result.get('results_count', 0)} forecast days")
            
            # Schemes context
            if 'myscheme' in actions:
                yield f"data: {json.dumps({'type': 'status', 'message': 'Checking government schemes...'})}\n\n"
                schemes_result = get_myscheme_context(state_name=state_name, query=prompt, optimize=True)
                pipeline_context['schemes'] = schemes_result
                logger.info(f"Schemes: {schemes_result.get('results_count', 0)} schemes")
            
            # Mandi prices context
            if 'enam' in actions:
                yield f"data: {json.dumps({'type': 'status', 'message': 'Fetching mandi prices...'})}\n\n"
                prices_result = get_enam_price_context(state_name=state_name.upper())
                pipeline_context['prices'] = prices_result
                logger.info(f"Prices: {prices_result.get('results_count', 0)} commodities")
            
            # Web search context
            if 'web_search' in actions or 'web' in actions:
                yield f"data: {json.dumps({'type': 'status', 'message': 'Searching the web...'})}\n\n"
                web_result = get_web_search_context(optimized_query, max_results=5, scrape_content=True)
                pipeline_context['web_search'] = web_result
                
                # Extract URLs for frontend
                if web_result.get('success') and web_result.get('context', {}).get('urls'):
                    web_urls = [url for url in web_result['context']['urls'][:5]]
                
                logger.info(f"Web: {web_result.get('results_count', 0)} URLs, scraped: {web_result.get('scraped_count', 0)}")
            
            # YouTube context (skip if general query)
            if not is_general:
                yield f"data: {json.dumps({'type': 'status', 'message': 'Finding video resources...'})}\n\n"
                youtube_result = get_youtube_context(optimized_query, limit=5, skip_if_general=is_general)
                pipeline_context['youtube'] = youtube_result
                
                # Extract YouTube links for frontend
                if youtube_result.get('success') and youtube_result.get('context', {}).get('videos'):
                    youtube_results = youtube_result['context']['videos'][:5]
                
                logger.info(f"YouTube: {youtube_result.get('results_count', 0)} videos")
            
            # Step 3: Generate response with pipeline context
            yield f"data: {json.dumps({'type': 'status', 'message': 'Generating response...'})}\n\n"
            
            full_response = ""
            async for chunk in model_runner.run_pipeline(
                question=prompt,
                pipeline_context=pipeline_context,
                conversation_id=conversation_id,
                user_id=user_id,
                stream=True,
                push_to_db=False  # We'll push manually with metadata
            ):
                full_response += chunk
                yield f"data: {json.dumps({'type': 'text', 'chunk': chunk})}\n\n"
            
            # Step 4: Send sources after response is complete
            if web_urls:
                yield f"data: {json.dumps({'type': 'urls', 'urls': web_urls})}\n\n"
            
            if youtube_results:
                try:
                    # Clean YouTube results for JSON serialization
                    cleaned_youtube = []
                    for video in youtube_results:
                        cleaned_video = {}
                        for key, value in video.items():
                            if isinstance(value, str):
                                cleaned_video[key] = value.encode('utf-8', 'ignore').decode('utf-8')
                            else:
                                cleaned_video[key] = value
                        cleaned_youtube.append(cleaned_video)
                    
                    yield f"data: {json.dumps({'type': 'youtube', 'results': cleaned_youtube}, ensure_ascii=False)}\n\n"
                except Exception as youtube_error:
                    logger.error(f"Error serializing YouTube results: {youtube_error}")
            
            # Step 5: Save to database
            if full_response:
                metadata = None
                if web_urls or youtube_results:
                    metadata = {
                        'url': web_urls if web_urls else [],
                        'youtberelated': youtube_results if youtube_results else []
                    }
                
                push_to_supabase(
                    'chat_messages',
                    {
                        'conversation_id': conversation_id,
                        'user_id': user_id,
                        'message': full_response,
                        'sender': 'assistant',
                        'metadata': metadata
                    }
                )
                logger.info(f"Response saved to database with metadata: {bool(metadata)}")
            
            yield f"data: {json.dumps({'type': 'complete'})}\n\n"

        except Exception as e:
            logger.error(f"Error in chat_agri endpoint: {str(e)}", exc_info=True)
            yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"

    return StreamingResponse(event_stream(), media_type="text/event-stream")