"""
Test script for MyScheme and eNAM context retrieval in pipeline
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from brain.pipeline import get_myscheme_context, get_enam_price_context

def test_myscheme_kerala():
    """Test MyScheme with Kerala state (no optimization)"""
    print("\n" + "="*60)
    print("Test 1: MyScheme - Kerala Agriculture Schemes (All)")
    print("="*60)
    
    result = get_myscheme_context(state_name="Kerala", optimize=False)
    
    print(f"\nSuccess: {result['success']}")
    print(f"Source: {result['source']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        schemes = context['schemes']
        print(f"Total Available: {context.get('total_available', 0)}")
        print(f"Filtered Count: {context.get('filtered_count', 0)}")
        print(f"\nFirst 3 schemes:")
        for i, scheme in enumerate(schemes[:3]):
            print(f"\n  {i+1}. {scheme['name']}")
            print(f"     Level: {scheme['level']}")
            print(f"     Ministry: {scheme['ministry']}")
            print(f"     Tags: {', '.join(scheme['tags'][:5]) if scheme['tags'] else 'N/A'}")
            print(f"     Description: {scheme['description'][:100]}...")
    else:
        print(f"Error: {result.get('error')}")


def test_myscheme_central():
    """Test MyScheme with Central schemes"""
    print("\n" + "="*60)
    print("Test 2: MyScheme - Central Agriculture Schemes")
    print("="*60)
    
    result = get_myscheme_context(state_name="Central", optimize=False)
    
    print(f"\nSuccess: {result['success']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        schemes = context['schemes']
        print(f"\nCentral schemes found: {len([s for s in schemes if s['level'] == 'Central'])}")
        print(f"Sample schemes: {', '.join([s['short_title'] or s['slug'] for s in schemes[:5]])}")


def test_enam_kerala():
    """Test eNAM with Kerala state"""
    print("\n" + "="*60)
    print("Test 3: eNAM - Kerala Mandi Prices")
    print("="*60)
    
    result = get_enam_price_context(state_name="KERALA")
    
    print(f"\nSuccess: {result['success']}")
    print(f"Source: {result['source']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        prices = context['prices']
        print(f"Date Range: {result['date_range']}")
        
        if prices:
            print(f"\nFirst 5 price entries:")
            for i, price in enumerate(prices[:5]):
                print(f"\n  {i+1}. {price['commodity']} ({price['variety']})")
                print(f"     APMC: {price['apmc']}, {price['district']}")
                print(f"     Price Range: ₹{price['min_price']} - ₹{price['max_price']} per {price['unit']}")
                print(f"     Modal Price: ₹{price['modal_price']}")
        else:
            print(f"Note: {context.get('note', 'No trading data available')}")
    else:
        print(f"Error: {result.get('error')}")


def test_enam_with_dates():
    """Test eNAM with specific date range"""
    print("\n" + "="*60)
    print("Test 4: eNAM - Kerala Prices (Last Week)")
    print("="*60)
    
    result = get_enam_price_context(
        state_name="KERALA",
        from_date="2025-11-29",
        to_date="2025-12-06"
    )
    
    print(f"\nSuccess: {result['success']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        prices = context['prices']
        
        # Group by commodity
        if prices:
            commodities = set(p['commodity'] for p in prices)
            print(f"\nUnique commodities traded: {len(commodities)}")
            print(f"Sample commodities: {', '.join(list(commodities)[:10])}")


def test_myscheme_with_gemini():
    """Test MyScheme with Gemini optimization"""
    print("\n" + "="*60)
    print("Test 5: MyScheme - Gemini Optimized (Oil Palm Query)")
    print("="*60)
    
    query = "I want to start oil palm cultivation, what schemes are available?"
    result = get_myscheme_context(state_name="Kerala", query=query, optimize=True)
    
    print(f"\nQuery: {query}")
    print(f"Success: {result['success']}")
    print(f"Optimized: {result.get('optimized', False)}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        schemes = context['schemes']
        print(f"Total Available: {context.get('total_available', 0)}")
        print(f"Filtered to: {context.get('filtered_count', 0)}")
        print(f"\nRelevant schemes:")
        for i, scheme in enumerate(schemes):
            print(f"\n  {i+1}. {scheme['name']} ({scheme['slug']})")
            print(f"     Level: {scheme['level']}")
            print(f"     Tags: {', '.join(scheme['tags'][:5]) if scheme['tags'] else 'N/A'}")


def test_myscheme_vertical_garden():
    """Test MyScheme with vertical garden query"""
    print("\n" + "="*60)
    print("Test 6: MyScheme - Gemini Optimized (Vertical Garden)")
    print("="*60)
    
    query = "How can I start a vertical garden at my home?"
    result = get_myscheme_context(state_name="Kerala", query=query, optimize=True)
    
    print(f"\nQuery: {query}")
    print(f"Success: {result['success']}")
    print(f"Results Count: {result.get('results_count', 0)}")
    
    if result['success']:
        context = result['context']
        schemes = context['schemes']
        print(f"\nRelevant schemes:")
        for i, scheme in enumerate(schemes[:3]):
            print(f"\n  {i+1}. {scheme['name']}")
            print(f"     Description: {scheme['description'][:150]}...")


if __name__ == "__main__":
    print("\n🌾 Testing MyScheme and eNAM Context Retrieval")
    
    test_myscheme_kerala()
    test_myscheme_central()
    test_myscheme_with_gemini()
    test_myscheme_vertical_garden()
    test_enam_kerala()
    test_enam_with_dates()
    
    print("\n✅ All tests completed\n")
