"""
Test complete pipeline with Gemma3:4b model
Tests context retrieval + model generation
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

import asyncio
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


async def test_simple_query():
    """Test with a simple crop disease query"""
    print("\n" + "="*80)
    print("TEST 1: Simple Crop Disease Query (Malayalam)")
    print("="*80)
    
    query = "വാഴയിൽ ഇലത്തഴമ്പ് കണ്ടു എന്ത് ചെയ്യണം?"
    
    # Step 1: Process query
    print(f"\n📝 Query: {query}")
    processed = process_farmer_query(query)
    print(f"\n🔍 Processed:")
    print(f"   Actions: {processed.get('actions', [])}")
    print(f"   State: {processed.get('state_name', 'Unknown')}")
    print(f"   Translation: {processed.get('english_translation', '')}")
    
    # Step 2: Get context from vector DB
    pipeline_context = {}
    if 'vector_db' in processed.get('actions', []):
        print("\n📚 Fetching vector DB context...")
        vdb_result = get_vector_db_context(query, n_results=3)
        pipeline_context['vector_db'] = vdb_result
        print(f"   Retrieved: {vdb_result.get('results_count', 0)} documents")
    
    # Step 3: Generate response with model
    print("\n🤖 Generating response with Gemma3:4b...\n")
    print("-" * 80)
    
    full_response = ""
    async for chunk in model_runner.run_pipeline(
        question=query,
        pipeline_context=pipeline_context,
        stream=True,
        push_to_db=False
    ):
        print(chunk, end='', flush=True)
        full_response += chunk
    
    print("\n" + "-" * 80)
    print(f"\n✅ Response length: {len(full_response)} characters")


async def test_weather_query():
    """Test with weather + schemes query"""
    print("\n" + "="*80)
    print("TEST 2: Weather + Oil Palm Scheme Query")
    print("="*80)
    
    query = "I want to start oil palm farming, what schemes are available and how is the weather?"
    
    # Step 1: Process query
    print(f"\n📝 Query: {query}")
    processed = process_farmer_query(query)
    print(f"\n🔍 Processed:")
    print(f"   Actions: {processed.get('actions', [])}")
    print(f"   State: {processed.get('state_name', 'Kerala')}")
    
    # Step 2: Get contexts
    pipeline_context = {}
    
    # Weather
    if 'imd' in processed.get('actions', []):
        print("\n🌤️  Fetching weather...")
        weather_result = get_imd_weather_context(station_id="99952")
        pipeline_context['weather'] = weather_result
        print(f"   Retrieved: {weather_result.get('results_count', 0)} forecast days")
    
    # Schemes
    if 'myscheme' in processed.get('actions', []):
        print("\n🏛️  Fetching schemes...")
        schemes_result = get_myscheme_context(
            state_name="Kerala",
            query=query,
            optimize=True
        )
        pipeline_context['schemes'] = schemes_result
        print(f"   Retrieved: {schemes_result.get('results_count', 0)} schemes")
    
    # Step 3: Generate response
    print("\n🤖 Generating response with Gemma3:4b...\n")
    print("-" * 80)
    
    full_response = ""
    async for chunk in model_runner.run_pipeline(
        question=query,
        pipeline_context=pipeline_context,
        stream=True,
        push_to_db=False
    ):
        print(chunk, end='', flush=True)
        full_response += chunk
    
    print("\n" + "-" * 80)
    print(f"\n✅ Response length: {len(full_response)} characters")


async def test_market_price_query():
    """Test with market price query"""
    print("\n" + "="*80)
    print("TEST 3: Market Price Query (Hindi)")
    print("="*80)
    
    query = "आज केले का भाव क्या है?"
    
    # Step 1: Process query
    print(f"\n📝 Query: {query}")
    processed = process_farmer_query(query)
    print(f"\n🔍 Processed:")
    print(f"   Actions: {processed.get('actions', [])}")
    print(f"   Translation: {processed.get('english_translation', '')}")
    
    # Step 2: Get price context
    pipeline_context = {}
    
    if 'enam' in processed.get('actions', []):
        print("\n🌾 Fetching mandi prices...")
        prices_result = get_enam_price_context(
            state_name="KERALA",
            from_date="2025-11-29",
            to_date="2025-12-06"
        )
        pipeline_context['prices'] = prices_result
        print(f"   Retrieved: {prices_result.get('results_count', 0)} price entries")
    
    # Step 3: Generate response
    print("\n🤖 Generating response with Gemma3:4b...\n")
    print("-" * 80)
    
    full_response = ""
    async for chunk in model_runner.run_pipeline(
        question=query,
        pipeline_context=pipeline_context,
        stream=True,
        push_to_db=False
    ):
        print(chunk, end='', flush=True)
        full_response += chunk
    
    print("\n" + "-" * 80)
    print(f"\n✅ Response length: {len(full_response)} characters")


async def test_comprehensive_query():
    """Test with all context sources"""
    print("\n" + "="*80)
    print("TEST 4: Comprehensive Query (All Sources)")
    print("="*80)
    
    query = "How should I grow rice in Kerala? Include weather, prices, schemes, and best practices"
    
    # Step 1: Process query
    print(f"\n📝 Query: {query}")
    processed = process_farmer_query(query)
    print(f"\n🔍 Processed:")
    print(f"   Actions: {processed.get('actions', [])}")
    
    # Step 2: Get ALL contexts
    pipeline_context = {}
    
    print("\n📚 Fetching vector DB context...")
    vdb_result = get_vector_db_context("rice cultivation Kerala best practices", n_results=2)
    pipeline_context['vector_db'] = vdb_result
    print(f"   ✓ {vdb_result.get('results_count', 0)} documents")
    
    print("\n🌤️  Fetching weather...")
    weather_result = get_imd_weather_context(station_name="Kozhikode", state_name="Kerala")
    pipeline_context['weather'] = weather_result
    print(f"   ✓ {weather_result.get('results_count', 0)} forecast days")
    
    print("\n🏛️  Fetching schemes...")
    schemes_result = get_myscheme_context(state_name="Kerala", query=query, optimize=True)
    pipeline_context['schemes'] = schemes_result
    print(f"   ✓ {schemes_result.get('results_count', 0)} schemes")
    
    print("\n🌾 Fetching prices...")
    prices_result = get_enam_price_context(state_name="KERALA")
    pipeline_context['prices'] = prices_result
    print(f"   ✓ {prices_result.get('results_count', 0)} price entries")
    
    print("\n🎥 Fetching YouTube videos...")
    youtube_result = get_youtube_context("rice farming Kerala", limit=3)
    pipeline_context['youtube'] = youtube_result
    print(f"   ✓ {youtube_result.get('results_count', 0)} videos")
    
    # Step 3: Generate comprehensive response
    print("\n🤖 Generating comprehensive response with Gemma3:4b...\n")
    print("-" * 80)
    
    full_response = ""
    async for chunk in model_runner.run_pipeline(
        question=query,
        pipeline_context=pipeline_context,
        stream=True,
        push_to_db=False
    ):
        print(chunk, end='', flush=True)
        full_response += chunk
    
    print("\n" + "-" * 80)
    print(f"\n✅ Response length: {len(full_response)} characters")
    print(f"\n📊 Context sources used: {len(pipeline_context)}")


async def main():
    print("\n🌾 TESTING COMPLETE PIPELINE WITH GEMMA3:4B")
    print("=" * 80)
    
    # Test 1: Simple query
    await test_simple_query()
    
    # Test 2: Weather + Schemes
    await test_weather_query()
    
    # Test 3: Market prices
    await test_market_price_query()
    
    # Test 4: Comprehensive
    await test_comprehensive_query()
    
    print("\n" + "="*80)
    print("✅ ALL TESTS COMPLETED")
    print("="*80 + "\n")


if __name__ == "__main__":
    asyncio.run(main())
