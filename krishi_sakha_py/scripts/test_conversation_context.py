#!/usr/bin/env python3
"""
Test conversation context for query processor
Tests follow-up questions with last response context
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from brain.pipeline import process_farmer_query, get_youtube_context
import json

def test_without_context():
    """Test ambiguous query without context"""
    print("\n" + "="*80)
    print("TEST 1: WITHOUT CONVERSATION CONTEXT")
    print("="*80)
    
    query = "What about fertilizer?"
    print(f"\nQuery: {query}")
    print("Last Response: (empty)")
    
    result = process_farmer_query(query)
    
    print("\n📊 Result:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    return result

def test_with_context():
    """Test ambiguous query WITH context"""
    print("\n" + "="*80)
    print("TEST 2: WITH CONVERSATION CONTEXT")
    print("="*80)
    
    last_response = """Rice cultivation requires proper water management. 
    The field should be flooded to 5-10 cm depth during transplanting. 
    Maintain water level throughout the growing season."""
    
    query = "What about fertilizer?"
    
    print(f"\nLast Response: {last_response[:100]}...")
    print(f"Query: {query}")
    
    result = process_farmer_query(query, last_response=last_response)
    
    print("\n📊 Result:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    return result

def test_general_query():
    """Test general query should skip YouTube"""
    print("\n" + "="*80)
    print("TEST 3: GENERAL QUERY (Should skip YouTube)")
    print("="*80)
    
    query = "Hello, how are you?"
    print(f"\nQuery: {query}")
    
    result = process_farmer_query(query)
    is_general = result.get('is_general', False)
    
    print("\n📊 Query Processing Result:")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    
    # Test YouTube with skip_if_general
    print("\n🎥 Testing YouTube with skip_if_general flag...")
    youtube_result = get_youtube_context("test query", limit=5, skip_if_general=is_general)
    
    print("\n📊 YouTube Result:")
    print(f"   Success: {youtube_result.get('success')}")
    print(f"   Results Count: {youtube_result.get('results_count')}")
    print(f"   Skipped: {is_general}")
    
    return result, youtube_result

def test_follow_up_questions():
    """Test realistic follow-up conversation"""
    print("\n" + "="*80)
    print("TEST 4: REALISTIC FOLLOW-UP CONVERSATION")
    print("="*80)
    
    conversations = [
        {
            "last": "",
            "query": "How to control pests in banana plants?"
        },
        {
            "last": "For banana pest control, use neem oil spray (5ml per liter) weekly. Apply Beauveria bassiana for stem weevil control.",
            "query": "When should I apply it?"
        },
        {
            "last": "Apply neem oil spray early morning or evening. For Beauveria bassiana, apply during pseudostem injection at 3-4 months.",
            "query": "What's the price today?"
        }
    ]
    
    for i, conv in enumerate(conversations, 1):
        print(f"\n{'='*40}")
        print(f"Turn {i}")
        print(f"{'='*40}")
        
        if conv["last"]:
            print(f"\nLast: {conv['last'][:80]}...")
        else:
            print("\nLast: (empty - first message)")
        
        print(f"Query: {conv['query']}")
        
        result = process_farmer_query(conv["query"], last_response=conv["last"])
        
        print("\n📊 Understanding:")
        print(f"   Actions: {result.get('actions', [])}")
        print(f"   Is General: {result.get('is_general', False)}")
        print(f"   State: {result.get('state_name', 'Unknown')}")
        
        if result.get('english_translation'):
            print(f"   Translation: {result.get('english_translation')}")

if __name__ == "__main__":
    print("\n" + "🧪 CONVERSATION CONTEXT TEST SUITE" + "\n")
    
    # Test 1: Without context
    test_without_context()
    
    # Test 2: With context
    test_with_context()
    
    # Test 3: General query + YouTube skip
    test_general_query()
    
    # Test 4: Realistic follow-up
    test_follow_up_questions()
    
    print("\n" + "="*80)
    print("✅ ALL TESTS COMPLETED")
    print("="*80 + "\n")
