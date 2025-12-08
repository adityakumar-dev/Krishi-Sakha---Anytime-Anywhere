"""
Script to process pop2016.pdf and store in ChromaDB
Handles multi-page tables and paragraphs with continuity tracking
"""

import os
import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

import logging
from datetime import datetime
from data.functions.enhanced_pdf_parser import parse_pdf_enhanced
from data.functions.add_to_vector_db import PDFVectorDBManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def process_pop2016_pdf():
    """
    Process pop2016.pdf with enhanced parser and store in ChromaDB
    """
    # Configuration
    pdf_path = project_root / "data" / "pdfs" / "pop2016.pdf"
    
    if not pdf_path.exists():
        logger.error(f"PDF file not found: {pdf_path}")
        return False
    
    logger.info("="*80)
    logger.info("PROCESSING POP2016.PDF TO VECTOR DATABASE")
    logger.info("="*80)
    logger.info(f"PDF Path: {pdf_path}")
    logger.info(f"Timestamp: {datetime.now().isoformat()}")
    logger.info("="*80)
    
    try:
        # Step 1: Parse PDF with enhanced continuity tracking
        logger.info("\n📖 STEP 1: Parsing PDF with multi-page continuity...")
        logger.info("-" * 80)
        
        chunks = parse_pdf_enhanced(
            pdf_path=str(pdf_path),
            document_context="population statistics and demographic data of India",
            organization="Census Bureau / Government of India",
            document_type="statistical_report",
            document_category="demographics",
            year="2016",
            gemini_api_key=os.getenv("GEMINI_API_KEY")
        )
        
        logger.info(f"\n✅ Successfully parsed PDF into {len(chunks)} chunks")
        
        # Display summary
        logger.info("\n📊 CHUNK SUMMARY:")
        logger.info("-" * 80)
        tables = [c for c in chunks if c['metadata']['content_type'] == 'table']
        paragraphs = [c for c in chunks if c['metadata']['content_type'] == 'paragraph']
        multipage = [c for c in chunks if c['metadata']['is_multipage']]
        
        logger.info(f"Total chunks: {len(chunks)}")
        logger.info(f"  - Tables: {len(tables)}")
        logger.info(f"  - Paragraphs: {len(paragraphs)}")
        logger.info(f"  - Multi-page content: {len(multipage)}")
        
        if multipage:
            logger.info("\n📄 Multi-page content blocks:")
            for chunk in multipage[:5]:  # Show first 5
                meta = chunk['metadata']
                logger.info(f"   - {meta['content_type'].upper()}: pages {meta['start_page']}-{meta['end_page']} "
                          f"({meta['page_span']} pages)")
        
        # Show sample chunks
        logger.info("\n📝 SAMPLE CHUNKS:")
        logger.info("-" * 80)
        for i, chunk in enumerate(chunks[:3]):
            meta = chunk['metadata']
            text_preview = chunk['text'][:200].replace('\n', ' ')
            logger.info(f"\nChunk {i+1}:")
            logger.info(f"  Type: {meta['content_type']}")
            logger.info(f"  Pages: {meta['start_page']}-{meta['end_page']}")
            logger.info(f"  Preview: {text_preview}...")
        
        # Step 2: Store in ChromaDB
        logger.info("\n\n💾 STEP 2: Storing in ChromaDB...")
        logger.info("-" * 80)
        
        # Initialize vector DB manager
        db_manager = PDFVectorDBManager(
            vector_db_type="chroma",
            embedding_method="sentence_transformers",
            db_path=str(project_root / "chroma_db"),
            collection_name="krishi_sakha_docs"
        )
        
        logger.info("Generating embeddings for chunks...")
        
        # Prepare chunks with proper structure for vector DB
        vector_chunks = []
        for i, chunk in enumerate(chunks):
            vector_chunk = {
                'text': chunk['text'],
                'metadata': chunk['metadata'],
                'chunk_index': i,
                'source_file': chunk['metadata']['source_file'],
                'file_hash': chunk['metadata']['file_hash'],
                'created_at': chunk['metadata']['created_at']
            }
            vector_chunks.append(vector_chunk)
        
        # Generate embeddings
        texts = [chunk['text'] for chunk in vector_chunks]
        embeddings = db_manager.embedding_generator.generate_embeddings(texts)
        
        logger.info(f"Generated {len(embeddings)} embeddings")
        
        # Add to ChromaDB
        logger.info("Adding documents to ChromaDB...")
        db_manager.vector_db.add_documents(vector_chunks, embeddings)
        
        logger.info("\n" + "="*80)
        logger.info("✅ SUCCESS! pop2016.pdf processed and stored in ChromaDB")
        logger.info("="*80)
        logger.info(f"Total documents stored: {len(vector_chunks)}")
        logger.info(f"Collection: krishi_sakha_docs")
        logger.info(f"Database path: {project_root / 'chroma_db'}")
        logger.info("="*80)
        
        return True
        
    except Exception as e:
        logger.error("\n" + "="*80)
        logger.error(f"❌ ERROR: {e}")
        logger.error("="*80)
        import traceback
        logger.error(traceback.format_exc())
        return False


def test_search():
    """
    Test searching the vector database after processing
    """
    logger.info("\n\n🔍 TESTING SEARCH FUNCTIONALITY")
    logger.info("="*80)
    
    try:
        # Initialize DB manager
        db_manager = PDFVectorDBManager(
            vector_db_type="chroma",
            embedding_method="sentence_transformers",
            db_path=str(project_root / "chroma_db"),
            collection_name="krishi_sakha_docs"
        )
        
        # Test queries
        test_queries = [
            "What is the population of Delhi in 2016?",
            "Show me demographic statistics",
            "Tell me about population data in tables"
        ]
        
        for query in test_queries:
            logger.info(f"\nQuery: '{query}'")
            logger.info("-" * 60)
            
            # Generate query embedding
            query_embedding = db_manager.embedding_generator.generate_embeddings([query])[0]
            
            # Search
            results = db_manager.vector_db.search(query_embedding, n_results=3)
            
            if results and 'documents' in results and results['documents']:
                for i, (doc, metadata) in enumerate(zip(results['documents'][0], results['metadatas'][0])):
                    logger.info(f"\nResult {i+1}:")
                    logger.info(f"  Type: {metadata.get('content_type', 'unknown')}")
                    logger.info(f"  Pages: {metadata.get('start_page', '?')}-{metadata.get('end_page', '?')}")
                    logger.info(f"  Text: {doc[:150]}...")
            else:
                logger.info("  No results found")
        
        logger.info("\n" + "="*80)
        logger.info("✅ Search test completed")
        logger.info("="*80)
        
    except Exception as e:
        logger.error(f"Search test failed: {e}")


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Process pop2016.pdf to vector database")
    parser.add_argument("--test-search", action="store_true", help="Run search test after processing")
    parser.add_argument("--search-only", action="store_true", help="Only run search test (skip processing)")
    
    args = parser.parse_args()
    
    if args.search_only:
        test_search()
    else:
        success = process_pop2016_pdf()
        
        if success and args.test_search:
            test_search()
