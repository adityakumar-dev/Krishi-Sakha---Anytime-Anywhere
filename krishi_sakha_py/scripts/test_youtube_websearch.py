"""
Test script for YouTube and Web Search context retrieval in pipeline
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from brain.pipeline import get_youtube_context, get_web_search_context

def test_youtube_basic():
    """Test YouTube search with agricultural query"""
    print("\n" + "="*60)
    print("Test 1: YouTube - Basic Agricultural Query")
    print("="*60)
    
    query = "organic farming techniques"
    result = get_youtube_context(query, limit=5)
    
    print(f"\nQuery: {query}")
    print(f"Success: {result['success']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        videos = context['videos']
        print(f"\nTop 3 videos:")
        for i, video in enumerate(videos[:3]):
            print(f"\n  {i+1}. {video['title'][:60]}")
            print(f"     Channel: {video['channel']}")
            print(f"     Views: {video['views']}")


def test_web_search():
    """Test web search with scraping"""
    print("\n" + "="*60)
    print("Test 2: Web Search - Rice Cultivation (with scraping)")
    print("="*60)
    
    query = "rice cultivation Kerala"
    result = get_web_search_context(query, max_results=3, scrape_content=True)
    
    print(f"\nQuery: {query}")
    print(f"Success: {result['success']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    print(f"Scraped Count: {result.get('scraped_count', 0)}")
    
    if result['success']:
        context = result['context']
        pages = context.get('pages', [])
        
        if pages:
            print(f"\nScraped content from {len(pages)} pages:")
            for i, page in enumerate(pages[:2]):  # Show first 2
                print(f"\n  {i+1}. {page['title'][:60]}")
                print(f"     URL: {page['url'][:70]}...")
                if page.get('content'):
                    print(f"     Content: {page['content'][:150]}...")
                    print(f"     Length: {len(page['content'])} chars")
                else:
                    print(f"     Error: {page.get('error', 'No content')}")
        else:
            print(f"\nURLs only:")
            for i, url in enumerate(context['urls'][:3]):
                print(f"  {i+1}. {url[:80]}...")


if __name__ == "__main__":
    print("\n🎥🔍 Testing YouTube and Web Search")
    test_youtube_basic()
    test_web_search()
    print("\n✅ Tests completed\n")
