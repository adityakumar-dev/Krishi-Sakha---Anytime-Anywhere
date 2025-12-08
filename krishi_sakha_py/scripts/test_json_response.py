"""
Test pipeline with JSON response structure showing model output + sources
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

import asyncio
import json
from brain.pipeline import (
    process_farmer_query,
    get_vector_db_context,
    get_imd_weather_context,
    get_myscheme_context,
    get_enam_price_context,
    get_youtube_context,
    get_web_search_context
)
from brain.model_run import model_runner


async def test_pipeline_json_response():
    """Test pipeline and show complete JSON response structure"""
    
    query = "How to control pests in banana plants? What's the weather and price today?"
    
    print("\n" + "="*80)
    print("TESTING PIPELINE WITH JSON RESPONSE STRUCTURE")
    print("="*80)
    print(f"\n📝 Query: {query}\n")
    
    # Step 1: Process query
    print("🔍 Step 1: Processing query...")
    processed = process_farmer_query(query)
    print(f"   Actions: {processed.get('actions', [])}")
    print(f"   State: {processed.get('state_name', 'Kerala')}")
    
    # Step 2: Fetch all contexts
    print("\n📚 Step 2: Fetching contexts...")
    pipeline_context = {}
    
    # Check if general query
    is_general = processed.get('is_general', False)
    
    # Vector DB
    print("   - Vector DB...")
    vdb_result = get_vector_db_context(query, n_results=3)
    pipeline_context['vector_db'] = vdb_result
    print(f"     ✓ {vdb_result.get('results_count', 0)} documents")
    
    # Weather
    print("   - Weather...")
    weather_result = get_imd_weather_context(station_name="Kozhikode", state_name="Kerala")
    pipeline_context['weather'] = weather_result
    print(f"     ✓ {weather_result.get('results_count', 0)} forecast days")
    
    # Schemes
    print("   - Schemes...")
    schemes_result = get_myscheme_context(state_name="Kerala", query=query, optimize=True)
    pipeline_context['schemes'] = schemes_result
    print(f"     ✓ {schemes_result.get('results_count', 0)} schemes")
    
    # Prices
    print("   - Mandi prices...")
    prices_result = get_enam_price_context(state_name="KERALA", from_date="2025-11-29", to_date="2025-12-06")
    pipeline_context['prices'] = prices_result
    print(f"     ✓ {prices_result.get('results_count', 0)} price entries")
    
    # YouTube (skip if general query)
    print("   - YouTube videos...")
    youtube_result = get_youtube_context("banana pest control", limit=5, skip_if_general=is_general)
    pipeline_context['youtube'] = youtube_result
    print(f"     ✓ {youtube_result.get('results_count', 0)} videos" + (" (skipped - general query)" if is_general else ""))
    
    # Web search
    print("   - Web search...")
    web_result = get_web_search_context("banana pest management Kerala", max_results=5, scrape_content=False)
    pipeline_context['web_search'] = web_result
    print(f"     ✓ {web_result.get('results_count', 0)} URLs")
    
    # Step 3: Generate model response
    print("\n🤖 Step 3: Generating response with Gemma3:4b...")
    print("-" * 80)
    
    model_response = ""
    async for chunk in model_runner.run_pipeline(
        question=query,
        pipeline_context=pipeline_context,
        stream=True,
        push_to_db=False
    ):
        print(chunk, end='', flush=True)
        model_response += chunk
    
    print("\n" + "-" * 80)
    
    # Step 4: Build final JSON response structure
    print("\n📦 Step 4: Building JSON response structure...\n")
    
    # Extract YouTube links
    youtube_links = []
    if youtube_result.get('success') and youtube_result.get('context', {}).get('videos'):
        for video in youtube_result['context']['videos'][:5]:
            youtube_links.append({
                'title': video['title'],
                'url': video['url'],
                'channel': video['channel'],
                'views': video['views'],
                'duration': video['duration']
            })
    
    # Extract top 5 source URLs
    source_urls = []
    
    # From web search
    if web_result.get('success') and web_result.get('context', {}).get('urls'):
        for url in web_result['context']['urls'][:5]:
            source_urls.append({
                'type': 'web',
                'url': url
            })
    
    # From vector DB (source PDFs)
    if vdb_result.get('success') and vdb_result.get('context'):
        seen_sources = set()
        for doc in vdb_result['context'][:3]:
            source = doc.get('metadata', {}).get('source_file', 'Unknown')
            if source not in seen_sources and len(source_urls) < 5:
                seen_sources.add(source)
                source_urls.append({
                    'type': 'knowledge_base',
                    'source': source,
                    'pages': f"{doc.get('metadata', {}).get('start_page')}-{doc.get('metadata', {}).get('end_page')}"
                })
    
    # Build complete JSON response
    response_json = {
        'query': {
            'original': query,
            'processed': {
                'actions': processed.get('actions', []),
                'state': processed.get('state_name', 'Kerala'),
                'english_translation': processed.get('english_translation', query)
            }
        },
        'response': {
            'text': model_response,
            'length': len(model_response),
            'language': 'en'  # Can be detected from query processor
        },
        'sources': {
            'youtube_videos': youtube_links,
            'reference_urls': source_urls[:5],
            'context_summary': {
                'vector_db_docs': vdb_result.get('results_count', 0),
                'weather_forecast_days': weather_result.get('results_count', 0),
                'schemes_found': schemes_result.get('results_count', 0),
                'price_entries': prices_result.get('results_count', 0),
                'web_urls': web_result.get('results_count', 0)
            }
        },
        'metadata': {
            'timestamp': '2025-12-07T12:00:00Z',
            'model': 'gemma3:4b',
            'context_sources_used': [k for k, v in pipeline_context.items() if v.get('success')],
            'weather_station': weather_result.get('context', {}).get('station_name', 'Unknown') if weather_result.get('success') else None
        }
    }
    
    # Print formatted JSON
    print("="*80)
    print("FINAL JSON RESPONSE STRUCTURE")
    print("="*80)
    print(json.dumps(response_json, indent=2, ensure_ascii=False))
    print("\n" + "="*80)
    
    # Save to file
    output_file = 'pipeline_response_example.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(response_json, f, indent=2, ensure_ascii=False)
    
    print(f"\n✅ JSON response saved to: {output_file}")
    print(f"\n📊 Summary:")
    print(f"   - Model response: {len(model_response)} characters")
    print(f"   - YouTube videos: {len(youtube_links)}")
    print(f"   - Reference URLs: {len(source_urls)}")
    print(f"   - Context sources: {len([k for k, v in pipeline_context.items() if v.get('success')])}")


if __name__ == "__main__":
    asyncio.run(test_pipeline_json_response())
