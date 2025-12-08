
from data.functions.add_to_vector_db  import PDFVectorDBManager
from scripts.imd_handler import get_imd_weather, get_station_by_name, get_stations_by_state
from scripts.enam_price import get_mandi_prices
from configs.supabase_key import SUPABASE
from modules.youtube.youtube_search import search_youtube
from modules.search.searxng_json import searxng_search
from modules.scrapper.scrapper import FastPlaywrightScraper
import logging
import asyncio
import requests
import os
from pathlib import Path
import google.generativeai as genai
from configs.external_keys import GEMINI_API_KEY
from configs.model_config import FARMER_QUERY_PROCESS_SYSTEM_MESSAGE
import time

# Use the provided API key for faster processing
API_KEY = os.getenv('GEMINI_API_KEY') or 'AIzaSyAvdI4MfjJRIare-G6c0VEM9KnwaIJTj1o'
genai.configure(api_key=API_KEY)
model = genai.GenerativeModel('gemini-2.5-flash')

import json
from typing import Dict, List, Optional

logger = logging.getLogger(__name__)

def process_farmer_query(query: str, last_response: str = "") -> Dict:
    """
    Process farmer query using Gemini AI and extract structured JSON
    
    Args:
        query: Farmer's query (can be in English, Malayalam, or Hinglish)
        last_response: Last assistant response for context (optional)
    
    Returns:
        Dictionary with:
        - is_general: bool (True if greeting/chit-chat)
        - actions: List of pipeline actions to execute
        - state_name: Detected state (default: Kerala)
        - english_translation: If query was in regional language
        - optimized_query: If web search is needed
        - generate: bool (False if not agriculture-related)
    """
    
    try:
        logger.info(f"🔍 Processing query: {query[:100]}...")
        logger.info(f"🔑 Using API Key: {API_KEY[:20]}...")
        logger.info(f"🤖 Model: gemini-2.5-flash")
        
        # Build prompt with optional context
        prompt = f"{FARMER_QUERY_PROCESS_SYSTEM_MESSAGE}\n\n"
        if last_response:
            prompt += f"Last Assistant Response: {last_response[:500]}\n\n"
        prompt += f"Current Query: {query}"
        
        # Retry logic with exponential backoff for quota errors
        max_retries = 3
        retry_delay = 2  # Start with 2 seconds
        
        for attempt in range(max_retries):
            try:
                # Call Gemini 2.5 Flash with system message
                response = model.generate_content(prompt)
                response_text = response.text.strip()
                break  # Success, exit retry loop
                
            except Exception as api_error:
                error_str = str(api_error)
                
                # Check if it's a quota error (429)
                if "429" in error_str or "quota" in error_str.lower():
                    if attempt < max_retries - 1:
                        logger.warning(f"⚠️  Quota limit hit, retrying in {retry_delay}s (attempt {attempt + 1}/{max_retries})...")
                        time.sleep(retry_delay)
                        retry_delay *= 2  # Exponential backoff: 2s, 4s, 8s
                    else:
                        logger.error(f"❌ Max retries reached, quota still exceeded")
                        raise api_error
                else:
                    # Not a quota error, raise immediately
                    raise api_error
        
        # Extract JSON from response
        # Try to find JSON block if wrapped in markdown
        if "```json" in response_text:
            json_start = response_text.find("```json") + 7
            json_end = response_text.find("```", json_start)
            json_str = response_text[json_start:json_end].strip()
        elif "```" in response_text:
            json_start = response_text.find("```") + 3
            json_end = response_text.find("```", json_start)
            json_str = response_text[json_start:json_end].strip()
        else:
            # Try to find JSON object directly
            json_start = response_text.find("{")
            json_end = response_text.rfind("}") + 1
            if json_start >= 0 and json_end > json_start:
                json_str = response_text[json_start:json_end]
            else:
                json_str = response_text
        
        # Parse JSON
        result = json.loads(json_str)
        
        logger.info(f"✅ Query processed: actions={result.get('actions', [])} | is_general={result.get('is_general', False)}")
        
        return result
        
    except json.JSONDecodeError as e:
        logger.error(f"❌ JSON parsing error: {e}")
        logger.error(f"Response was: {response_text}")
        # Return safe default
        return {
            "is_general": False,
            "actions": ["general"],
            "state_name": "Kerala",
            "generate": True,
            "error": str(e)
        }
    except Exception as e:
        logger.error(f"❌ Error processing query: {e}")
        return {
            "is_general": False,
            "actions": ["general"],
            "state_name": "Kerala",
            "generate": True,
            "error": str(e)
        }


def extract_query_metadata(processed_query: Dict) -> Dict:
    """
    Extract useful metadata from processed query for downstream handling
    
    Args:
        processed_query: Output from process_farmer_query()
    
    Returns:
        Metadata dictionary with:
        - clean_query: English version of query
        - actions: Pipeline actions
        - state: State name
        - search_query: If web search needed
        - is_actionable: True if agriculture-related
    """
    
    return {
        "clean_query": processed_query.get("english_translation", processed_query.get("query", "")),
        "actions": processed_query.get("actions", []),
        "state": processed_query.get("state_name", "Kerala"),
        "search_query": processed_query.get("optimized_query", ""),
        "is_actionable": processed_query.get("generate", True),
        "is_general": processed_query.get("is_general", False)
    }


def get_vector_db_context(query: str, optimized_query: str = None, n_results: int = 5) -> Dict:
    """
    Retrieve context from vector database (pop2016.pdf knowledge base)
    
    Args:
        query: Original user query
        optimized_query: Optimized query from Gemini (if available)
        n_results: Number of results to retrieve
        
    Returns:
        Dict with context documents and metadata
    """
    try:
        logger.info(f"📚 Retrieving vector DB context for: {query[:100]}...")
        
        # Initialize vector DB manager
        db_manager = PDFVectorDBManager(
            db_path="./chroma_db",
            collection_name="krishi_sakha_docs"
        )
        
        # Use optimized query if available, otherwise use original
        search_query = optimized_query or query
        logger.info(f"🔍 Search query: {search_query[:100]}...")
        
        # Generate embedding for the query
        query_embedding = db_manager.embedding_generator.generate_embeddings([search_query])[0]
        
        # Search vector database
        results = db_manager.vector_db.search(query_embedding, n_results=n_results)
        
        # Format results
        context_docs = []
        if results and 'documents' in results and results['documents']:
            for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
                context_docs.append({
                    'rank': i + 1,
                    'text': doc,
                    'metadata': {
                        'source_file': metadata.get('source_file', 'unknown'),
                        'start_page': metadata.get('start_page', '?'),
                        'end_page': metadata.get('end_page', '?'),
                        'content_type': metadata.get('content_type', 'unknown'),
                        'is_multipage': metadata.get('is_multipage', 'false'),
                        'organization': metadata.get('organization', 'unknown')
                    },
                    'preview': doc[:200] + '...' if len(doc) > 200 else doc
                })
        
        logger.info(f"✅ Retrieved {len(context_docs)} documents from vector DB")
        
        return {
            'success': True,
            'source': 'vector_db',
            'query': search_query,
            'results_count': len(context_docs),
            'context': context_docs
        }
        
    except Exception as e:
        logger.error(f"❌ Vector DB retrieval failed: {e}")
        return {
            'success': False,
            'source': 'vector_db',
            'error': str(e),
            'context': []
        }


def get_imd_weather_context(station_id: str = None, station_name: str = None, state_name: str = "Kerala") -> Dict:
    """
    Retrieve weather data from IMD (Indian Meteorological Department)
    
    Args:
        station_id: IMD station ID (e.g., '99952' for Dehradun, '43003' for Thiruvananthapuram)
        station_name: Name of the station (alternative to station_id)
        state_name: State name (default: Kerala) - used to find stations if neither station_id nor station_name provided
        
    Returns:
        Dict with weather data and forecast
    """
    try:
        # If no station_id provided, try to find one based on state
        if not station_id:
            if station_name:
                # Find by station name
                logger.info(f"🔍 Finding station ID for: {station_name}")
                station_info = get_station_by_name(station_name)
                if not station_info.get('success'):
                    logger.warning(f"Station '{station_name}' not found, trying state lookup")
                else:
                    station_id = station_info['station_id']
                    logger.info(f"✅ Found station ID: {station_id}")
            
            # If still no station_id, try to find first station in the state
            if not station_id and state_name:
                logger.info(f"🔍 Finding station in state: {state_name}")
                state_stations = get_stations_by_state(state_name)
                if state_stations.get('success') and state_stations.get('stations'):
                    # Use first station in the state
                    station_id = state_stations['stations'][0]['station_id']
                    logger.info(f"✅ Using first station in {state_name}: {station_id}")
        
        # Final fallback to Kerala default
        if not station_id:
            station_id = "43003"  # Thiruvananthapuram, Kerala
            logger.info(f"⚠️ No station specified, using Kerala default: {station_id}")
        
        logger.info(f"🌤️ Retrieving IMD weather for station: {station_id}")
        
        # Get weather data
        weather_data = get_imd_weather(station_id)
        
        if 'error' in weather_data:
            return {
                'success': False,
                'source': 'imd_weather',
                'error': weather_data['error'],
                'context': {}
            }
        
        # Format context for model
        forecast_summary = []
        for day in weather_data.get('forecast_period', []):
            forecast_summary.append({
                'date': day['date'],
                'day_offset': day['date_offset'],
                'max_temp': day['max'],
                'min_temp': day['min'],
                'description': day['desc'],
                'humidity_morning': day.get('rh_0830'),
                'humidity_evening': day.get('rh_1730'),
                'warning': day.get('warning', 'No warning')
            })
        
        context = {
            'station_name': weather_data.get('station', 'Unknown'),
            'station_id': station_id,
            'location': {
                'lat': weather_data.get('lat'),
                'lon': weather_data.get('lon')
            },
            'sun_timings': {
                'sunrise': weather_data.get('sunrise'),
                'sunset': weather_data.get('sunset'),
                'moonrise': weather_data.get('moonrise'),
                'moonset': weather_data.get('moonset')
            },
            'forecast': forecast_summary,
            'last_updated': weather_data.get('last_updated')
        }
        
        logger.info(f"✅ Retrieved weather data for {context['station_name']}")
        logger.info(f"   Forecast days: {len(forecast_summary)}")
        
        return {
            'success': True,
            'source': 'imd_weather',
            'station_id': station_id,
            'results_count': len(forecast_summary),
            'context': context
        }
        
    except Exception as e:
        logger.error(f"❌ IMD weather retrieval failed: {e}")
        return {
            'success': False,
            'source': 'imd_weather',
            'error': str(e),
            'context': {}
        }


def optimize_schemes_with_gemini(query: str, schemes: List[Dict]) -> List[str]:
    """
    Use Gemini to filter schemes relevant to user query
    
    Args:
        query: User's original query
        schemes: List of scheme dictionaries with slug, schemename, briefdescription
        
    Returns:
        List of relevant scheme slugs
    """
    try:
        if not schemes:
            return []
        
        # Create prompt for Gemini
        schemes_info = "\n\n".join([
            f"Slug: {s['slug']}\nName: {s['schemename']}\nDescription: {s['briefdescription']}"
            for s in schemes
        ])
        
        prompt = f"""You are a scheme recommendation assistant. Given a farmer's query and a list of government schemes, identify which schemes are relevant to the query.

User Query: {query}

Available Schemes:
{schemes_info}

Return ONLY a JSON array of slugs for relevant schemes. If no schemes match, return empty array [].
Format: ["slug1", "slug2", "slug3"]

Relevant scheme slugs:"""
        
        # Retry logic with exponential backoff for quota errors
        max_retries = 3
        retry_delay = 2
        
        for attempt in range(max_retries):
            try:
                response = model.generate_content(prompt)
                response_text = response.text.strip()
                break  # Success
                
            except Exception as api_error:
                error_str = str(api_error)
                if "429" in error_str or "quota" in error_str.lower():
                    if attempt < max_retries - 1:
                        logger.warning(f"⚠️  Quota limit hit in scheme optimization, retrying in {retry_delay}s...")
                        time.sleep(retry_delay)
                        retry_delay *= 2
                    else:
                        logger.error(f"❌ Max retries reached for scheme optimization")
                        raise api_error
                else:
                    raise api_error
        
        # Extract JSON array
        if "```json" in response_text:
            json_start = response_text.find("```json") + 7
            json_end = response_text.find("```", json_start)
            json_str = response_text[json_start:json_end].strip()
        elif "[" in response_text:
            json_start = response_text.find("[")
            json_end = response_text.rfind("]") + 1
            json_str = response_text[json_start:json_end]
        else:
            return []
        
        relevant_slugs = json.loads(json_str)
        logger.info(f"🎯 Gemini filtered {len(relevant_slugs)} relevant schemes from {len(schemes)}")
        return relevant_slugs
        
    except Exception as e:
        logger.error(f"⚠️ Scheme optimization failed: {e}, returning all schemes")
        return [s['slug'] for s in schemes]  # Fallback: return all


def get_myscheme_context(state_name: str = "Kerala", query: str = "", optimize: bool = True) -> Dict:
    """
    Retrieve government schemes from Supabase database
    
    Args:
        state_name: State name for filtering schemes (default: Kerala)
        query: User query for filtering relevant schemes with Gemini
        optimize: Whether to use Gemini to filter relevant schemes (default: True)
        
    Returns:
        Dict with schemes data
    """
    try:
        logger.info(f"🏛️ Retrieving schemes from Supabase for: {state_name}")
        
        # Fetch central schemes (always included)
        central_query = SUPABASE.table('schemes').select('*').eq('level', 'Central')
        central_response = central_query.execute()
        central_schemes = central_response.data if central_response.data else []
        
        logger.info(f"📋 Found {len(central_schemes)} Central schemes")
        
        # Fetch state-specific schemes if not "Central"
        state_schemes = []
        if state_name and state_name.lower() not in ["central", "all", "india"]:
            # Use @> (contains) operator for JSONB array - PostgREST syntax
            state_query = SUPABASE.table('schemes').select('*').filter('beneficiarystate', 'cs', json.dumps([state_name]))
            state_response = state_query.execute()
            state_schemes = state_response.data if state_response.data else []
            logger.info(f"📋 Found {len(state_schemes)} {state_name} schemes")
        
        # Combine schemes
        all_schemes = central_schemes + state_schemes
        
        if not all_schemes:
            return {
                'success': True,
                'source': 'myscheme',
                'state': state_name,
                'results_count': 0,
                'context': {'schemes': []}
            }
        
        # Optimize with Gemini if query provided
        relevant_slugs = None
        if optimize and query:
            # Prepare schemes for Gemini (only needed fields)
            schemes_for_gemini = [{
                'slug': s['slug'],
                'schemename': s['schemename'],
                'briefdescription': s.get('briefdescription', '')
            } for s in all_schemes]
            
            relevant_slugs = optimize_schemes_with_gemini(query, schemes_for_gemini)
            logger.info(f"🎯 Filtering to {len(relevant_slugs)} relevant schemes")
        
        # Filter schemes by relevant slugs or use all
        if relevant_slugs:
            filtered_schemes = [s for s in all_schemes if s['slug'] in relevant_slugs]
        else:
            filtered_schemes = all_schemes
        
        # Format schemes for model consumption
        formatted_schemes = []
        for scheme in filtered_schemes:
            formatted_schemes.append({
                'name': scheme.get('schemename', 'Unknown'),
                'slug': scheme.get('slug', ''),
                'level': scheme.get('level', 'Unknown'),
                'short_title': scheme.get('schemeshorttitle', ''),
                'state': scheme.get('beneficiarystate', []),
                'scheme_for': scheme.get('schemefor', 'Unknown'),
                'category': scheme.get('schemecategory', []),
                'ministry': scheme.get('nodalministryname', 'Unknown'),
                'description': scheme.get('briefdescription', ''),
                'tags': scheme.get('tags', []),
                'priority': scheme.get('priority', 0),
                'url': f"https://www.myscheme.gov.in/schemes/{scheme.get('slug', '')}"
            })
        
        logger.info(f"✅ Retrieved {len(formatted_schemes)} schemes for {state_name}")
        
        return {
            'success': True,
            'source': 'myscheme',
            'state': state_name,
            'optimized': optimize and query != "",
            'results_count': len(formatted_schemes),
            'context': {
                'schemes': formatted_schemes,
                'total_available': len(all_schemes),
                'filtered_count': len(formatted_schemes)
            }
        }
        
    except Exception as e:
        logger.error(f"❌ MyScheme retrieval failed: {e}")
        return {
            'success': False,
            'source': 'myscheme',
            'error': str(e),
            'context': {'schemes': []}
        }


def normalize_state_name_for_enam(state_name: str) -> str:
    """
    Normalize state name to match eNAM API format
    
    Args:
        state_name: State name in any format
    
    Returns:
        Normalized state name matching eNAM API format
    """
    # eNAM state names list
    enam_states = [
        "Andaman & Nicobar Islands", "Andhra Pradesh", "Assam", "Bihar",
        "Chandigarh", "Chhattisgarh", "Goa", "Gujarat", "Haryana",
        "Himachal Pradesh", "Jammu & Kashmir", "Jharkhand", "Karnataka",
        "Kerala", "Madhya Pradesh", "Maharashtra", "Nagaland", "Odisha",
        "Puducherry", "Punjab", "Rajasthan", "Tamil Nadu", "Telangana",
        "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
    ]
    
    # Normalize input
    normalized = state_name.strip()
    
    # Direct match (case-insensitive)
    for enam_state in enam_states:
        if normalized.lower() == enam_state.lower():
            return enam_state
    
    # Partial match
    for enam_state in enam_states:
        if normalized.lower() in enam_state.lower() or enam_state.lower() in normalized.lower():
            return enam_state
    
    # Default to Kerala if no match
    logger.warning(f"State '{state_name}' not found in eNAM list, defaulting to Kerala")
    return "Kerala"


def get_enam_price_context(state_name: str = "KERALA", from_date: str = None, to_date: str = None, max_days_back: int = 7) -> Dict:
    """
    Retrieve mandi prices from eNAM (National Agriculture Market)
    
    Args:
        state_name: State name (will be normalized to match eNAM format)
        from_date: Start date in YYYY-MM-DD format (default: today)
        to_date: End date in YYYY-MM-DD format (default: today)
        max_days_back: Maximum days to look back if no data found (default: 7)
        
    Returns:
        Dict with mandi price data
    """
    from datetime import datetime, timedelta
    
    try:
        logger.info(f"🌾 Retrieving eNAM prices for: {state_name}")
        
        # Normalize state name to match eNAM format
        normalized_state = normalize_state_name_for_enam(state_name)
        logger.info(f"   Normalized to: {normalized_state}")
        
        # Set default dates if not provided
        if not to_date:
            to_date = datetime.now().strftime('%Y-%m-%d')
        if not from_date:
            from_date = to_date
        
        # Try fetching data, with fallback to previous days if no data found
        result = None
        attempts = 0
        current_from_date = datetime.strptime(from_date, '%Y-%m-%d')
        current_to_date = datetime.strptime(to_date, '%Y-%m-%d')
        
        while attempts < max_days_back:
            try:
                # Run async function in sync context
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                try:
                    from_str = current_from_date.strftime('%Y-%m-%d')
                    to_str = current_to_date.strftime('%Y-%m-%d')
                    logger.info(f"   Attempting fetch for date range: {from_str} to {to_str}")
                    
                    result = loop.run_until_complete(
                        get_mandi_prices(from_str, to_str, normalized_state)
                    )
                finally:
                    loop.close()
                
                # Check if we got data
                if result and 'data' in result and len(result.get('data', [])) > 0:
                    logger.info(f"   ✓ Found {len(result['data'])} price records")
                    break
                else:
                    # No data, try previous day
                    attempts += 1
                    current_from_date -= timedelta(days=1)
                    current_to_date -= timedelta(days=1)
                    logger.warning(f"   No data found, trying previous day (attempt {attempts}/{max_days_back})")
                    
            except Exception as e:
                logger.error(f"   Error fetching prices: {e}")
                attempts += 1
                current_from_date -= timedelta(days=1)
                current_to_date -= timedelta(days=1)
        
        if not result or 'error' in result or not result.get('data'):
            return {
                'success': False,
                'source': 'enam_prices',
                'error': result.get('error', 'No price data available') if result else 'Failed to fetch prices',
                'context': {'prices': []}
            }
        
        # Format price data for model
        prices_data = result.get('data', [])
        
        formatted_prices = []
        for item in prices_data:
            formatted_prices.append({
                'commodity': item.get('commodity', 'Unknown'),
                'variety': item.get('variety', ''),
                'apmc': item.get('apmc_name', 'Unknown'),
                'district': item.get('district', ''),
                'min_price': item.get('min_price', 0),
                'max_price': item.get('max_price', 0),
                'modal_price': item.get('modal_price', 0),
                'arrival_date': item.get('arrival_date', ''),
                'unit': item.get('unit', 'Quintal')
            })
        
        logger.info(f"✅ Retrieved {len(formatted_prices)} price entries for {state_name}")
        
        return {
            'success': True,
            'source': 'enam_prices',
            'state': state_name,
            'date_range': result.get('date_range', f"{from_date or 'today'} to {to_date or 'today'}"),
            'results_count': len(formatted_prices),
            'context': {
                'prices': formatted_prices,
                'note': result.get('note', '')
            }
        }
        
    except Exception as e:
        logger.error(f"❌ eNAM price retrieval failed: {e}")
        return {
            'success': False,
            'source': 'enam_prices',
            'error': str(e),
            'context': {'prices': []}
        }


def get_youtube_context(query: str, limit: int = 5, skip_if_general: bool = False) -> Dict:
    """
    Search YouTube for relevant agricultural videos
    
    Args:
        query: Search query (can be optimized query from Gemini)
        limit: Maximum number of videos to retrieve (default: 5)
        skip_if_general: If True, returns empty result (used when is_general=True)
        
    Returns:
        Dict with YouTube video results
    """
    try:
        if skip_if_general:
            logger.info("⏭️  Skipping YouTube search (general query)")
            return {
                'success': True,
                'source': 'youtube',
                'query': query,
                'results_count': 0,
                'context': {'videos': []}
            }
        
        logger.info(f"🎥 Searching YouTube for: {query[:100]}...")
        
        videos = search_youtube(query, limit=limit)
        
        # Check for errors
        if videos and isinstance(videos[0], dict) and 'error' in videos[0]:
            return {
                'success': False,
                'source': 'youtube',
                'error': videos[0]['error'],
                'context': {'videos': []}
            }
        
        # Format video data for model
        formatted_videos = []
        for video in videos:
            formatted_videos.append({
                'title': video.get('title', 'Unknown'),
                'video_id': video.get('video_id', ''),
                'url': video.get('url', ''),
                'thumbnail': video.get('thumbnail', ''),
                'channel': video.get('channel', 'Unknown'),
                'channel_url': video.get('channel_url', ''),
                'duration': video.get('duration', ''),
                'views': video.get('views', ''),
                'published': video.get('published', '')
            })
        
        logger.info(f"✅ Retrieved {len(formatted_videos)} YouTube videos")
        
        return {
            'success': True,
            'source': 'youtube',
            'query': query,
            'results_count': len(formatted_videos),
            'context': {'videos': formatted_videos}
        }
        
    except Exception as e:
        logger.error(f"❌ YouTube search failed: {e}")
        return {
            'success': False,
            'source': 'youtube',
            'error': str(e),
            'context': {'videos': []}
        }


def get_web_search_context(query: str, max_results: int = 5, scrape_content: bool = True, instance_url: str = "http://localhost:8080") -> Dict:
    """
    Search the web using SearxNG and optionally scrape content from results
    
    Args:
        query: Search query (can be optimized query from Gemini)
        max_results: Maximum number of results to retrieve (default: 5)
        scrape_content: Whether to scrape and extract content from URLs (default: True)
        instance_url: SearxNG instance URL (default: localhost:8080 - local Docker instance)
        
    Returns:
        Dict with web search results (URLs and optionally scraped content)
    """
    try:
        logger.info(f"🔍 Web search for: {query[:100]}...")
        
        urls = searxng_search(query, instance_url=instance_url, max_results=max_results)
        
        logger.info(f"✅ Retrieved {len(urls)} web search results")
        
        # Optionally scrape content from URLs
        scraped_content = []
        if scrape_content and urls:
            try:
                logger.info(f"📄 Scraping content from {len(urls)} URLs...")
                
                # Run async scraper in sync context
                scraper = FastPlaywrightScraper(
                    headless=True,
                    timeout=4000,
                    max_parallel=5
                )
                
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                try:
                    results = loop.run_until_complete(
                        scraper.scrape_multiple(urls, main_selector="main, article, .content")
                    )
                finally:
                    loop.close()
                
                # Format scraped content
                for r in results:
                    if r.get('success'):
                        scraped_content.append({
                            'url': r.get('url'),
                            'title': r.get('title'),
                            'content': (r.get('content') or '').strip()[:5000],  # Limit to 5000 chars
                            'html_length': r.get('html_length', 0)
                        })
                    else:
                        scraped_content.append({
                            'url': r.get('url'),
                            'title': 'Failed to scrape',
                            'content': '',
                            'error': r.get('error')
                        })
                
                logger.info(f"✅ Successfully scraped {len([s for s in scraped_content if s.get('content')])} pages")
                
            except Exception as scrape_error:
                logger.warning(f"⚠️ Content scraping failed: {scrape_error}, returning URLs only")
        
        context_data = {
            'urls': urls,
            'scraped': scrape_content
        }
        
        if scraped_content:
            context_data['pages'] = scraped_content
        
        return {
            'success': True,
            'source': 'web_search',
            'query': query,
            'results_count': len(urls),
            'scraped_count': len(scraped_content) if scraped_content else 0,
            'context': context_data
        }
        
    except Exception as e:
        logger.error(f"❌ Web search failed: {e}")
        return {
            'success': False,
            'source': 'web_search',
            'error': str(e),
            'context': {'urls': [], 'pages': []}
        }


def process_query(query: str) -> Dict:
    """
    Main query processing function
    Wraps process_farmer_query and extracts metadata
    
    Args:
        query: Farmer's query
        
    Returns:
        Processed query with actions and metadata
    """
    
    # Process query with Gemini
    processed = process_farmer_query(query)
    
    # Extract metadata
    metadata = extract_query_metadata(processed)
    
    return {
        "original_query": query,
        "processed": processed,
        "metadata": metadata
    }
    









