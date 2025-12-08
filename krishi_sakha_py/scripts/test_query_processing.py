"""
Test script for farmer query processing
"""

import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from brain.pipeline import process_query
import json
import logging

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# Test queries
test_queries = [
    # English queries
    "What is the best fertilizer for rice cultivation?",
    "Tell me about coconut diseases and management",
    "What is today's banana price in the market?",
    
    # Malayalam queries (simulated)
    "നെന്ത്രൻ വാഴയ്ക്ക് ഇന്ന് വില എത്ര?",  # What is today's nendran banana price?
    "വാഴയിൽ ഇലത്തഴമ്പ് കണ്ടു എന്ത് ചെയ്യണം?",  # I saw leaf spot on banana, what to do?
    
    # Greetings
    "Hello, how are you?",
    "നമസ്കാരം, എങ്ങനെയുണ്ട്?",  # Malayalam greeting
    
    # Non-agriculture queries
    "What is the capital of India?",
    "Tell me a joke"
]

def test_query_processing():
    """Test query processing with various inputs"""
    
    logger.info("="*80)
    logger.info("FARMER QUERY PROCESSING TEST")
    logger.info("="*80)
    
    for i, query in enumerate(test_queries, 1):
        logger.info(f"\n\n{'='*80}")
        logger.info(f"Test {i}: {query[:60]}...")
        logger.info("="*80)
        
        try:
            result = process_query(query)
            
            logger.info("\n📋 ORIGINAL QUERY:")
            logger.info(f"  {result['original_query']}")
            
            logger.info("\n🔍 PROCESSED RESULT:")
            logger.info(json.dumps(result['processed'], indent=2))
            
            logger.info("\n📊 METADATA:")
            logger.info(json.dumps(result['metadata'], indent=2))
            
            # Highlight key findings
            metadata = result['metadata']
            logger.info("\n✨ KEY FINDINGS:")
            logger.info(f"  • Is General Chat: {metadata['is_general']}")
            logger.info(f"  • Is Actionable: {metadata['is_actionable']}")
            logger.info(f"  • State: {metadata['state']}")
            logger.info(f"  • Actions: {', '.join(metadata['actions'])}")
            if metadata['clean_query']:
                logger.info(f"  • Clean Query: {metadata['clean_query']}")
            if metadata['search_query']:
                logger.info(f"  • Search Query: {metadata['search_query']}")
            
        except Exception as e:
            logger.error(f"❌ Error processing query: {e}")
            import traceback
            logger.error(traceback.format_exc())
    
    logger.info("\n" + "="*80)
    logger.info("✅ TEST COMPLETE")
    logger.info("="*80)


if __name__ == "__main__":
    test_query_processing()
