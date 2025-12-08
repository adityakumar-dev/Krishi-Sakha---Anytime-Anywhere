"""
Test vector DB context retrieval function
"""

import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

os.environ['GEMINI_API_KEY'] = 'AIzaSyAKFZ0v5_nRKOQqe2adLH2MBl2YvKgRpxo'

from brain.pipeline import get_vector_db_context, process_farmer_query
import json

# Test queries
test_queries = [
    "When should I remove old pepper vines after underplanting?",
    "What are the best fertilizer recommendations for rice?",
    "How to manage coffee diseases?",
    "Tell me about SRI method for paddy cultivation"
]

print("="*80)
print("TESTING VECTOR DB CONTEXT RETRIEVAL")
print("="*80)

for query in test_queries:
    print(f"\n{'='*80}")
    print(f"Query: {query}")
    print('='*80)
    
    # First process the query to get optimized search terms
    processed = process_farmer_query(query)
    optimized_query = processed.get('optimized_query', query)
    
    print(f"\nOptimized Query: {optimized_query}")
    print(f"Actions: {processed.get('actions', [])}")
    
    # Get vector DB context
    if 'vector_db' in processed.get('actions', []):
        context = get_vector_db_context(query, optimized_query, n_results=3)
        
        if context['success']:
            print(f"\n📚 Retrieved {context['results_count']} documents:\n")
            
            for doc in context['context']:
                print(f"Result {doc['rank']}:")
                print(f"  Source: {doc['metadata']['source_file']}")
                print(f"  Pages: {doc['metadata']['start_page']}-{doc['metadata']['end_page']}")
                print(f"  Type: {doc['metadata']['content_type']}")
                print(f"  Preview: {doc['preview']}")
                print()
        else:
            print(f"\n❌ Error: {context.get('error', 'Unknown error')}")
    else:
        print("\n⚠️  No vector_db action in query")

print("\n" + "="*80)
print("✅ Test completed!")
print("="*80)
