"""
Full PDF Processing with Parallel API Keys
Processes all 401 pages with 3 API keys in parallel for speed
"""

import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

import logging
from data.functions.enhanced_pdf_parser import parse_pdf_enhanced
from data.functions.add_to_vector_db import PDFVectorDBManager

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# Three API keys for parallel processing
API_KEYS = [
    "AIzaSyAemwJ8-4HHJPYI2RSXeN647pV_DjDq5NM",
    "AIzaSyD9L0ra8xFS6BKG_pgtopnbd0KTrU2vics",
    "AIzaSyARvv5bLqfw1VttRNloMAMa83TBaQH-vOQ",
]

pdf_path = project_root / "data" / "pdfs" / "pop2016.pdf"

try:
    logger.info("="*80)
    logger.info("PROCESSING FULL pop2016.pdf WITH PARALLEL API KEYS")
    logger.info("="*80)
    logger.info(f"PDF: {pdf_path.name}")
    logger.info(f"API Keys: {len(API_KEYS)}")
    logger.info(f"Parallel: Yes")
    logger.info("="*80 + "\n")
    
    # Parse with all 3 API keys in parallel
    logger.info("📖 Parsing all 401 pages with parallel processing...")
    chunks = parse_pdf_enhanced(
        pdf_path=str(pdf_path),
        document_context="agricultural practices and crop recommendations",
        organization="Kerala Agricultural University",
        document_type="agricultural_guide",
        document_category="agriculture",
        year="2016",
        api_keys=API_KEYS,
        parallel=True
    )
    
    logger.info(f"\n✅ Successfully parsed PDF into {len(chunks)} chunks")
    
    # Show summary
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
        for chunk in multipage[:10]:
            meta = chunk['metadata']
            logger.info(f"   - {meta['content_type'].upper()}: pages {meta['start_page']}-{meta['end_page']} "
                      f"({meta['page_span']} pages)")
    
    # Store in ChromaDB
    logger.info("\n💾 STEP 2: Storing in ChromaDB...")
    logger.info("-" * 80)
    
    db = PDFVectorDBManager(
        vector_db_type="chroma",
        embedding_method="sentence_transformers",
        db_path=str(project_root / "chroma_db"),
        collection_name="krishi_sakha_docs"
    )
    
    logger.info("Generating embeddings for chunks...")
    texts = [c['text'] for c in chunks]
    embeddings = db.embedding_generator.generate_embeddings(texts)
    logger.info(f"Generated {len(embeddings)} embeddings")
    
    # Prepare chunks with proper metadata
    vector_chunks = []
    for i, chunk in enumerate(chunks):
        v_chunk = {
            'text': chunk['text'],
            'metadata': chunk['metadata'],
            'chunk_index': i,
            'source_file': chunk['metadata']['source_file'],
            'file_hash': chunk['metadata']['file_hash'],
            'created_at': chunk['metadata']['created_at']
        }
        vector_chunks.append(v_chunk)
    
    # Add to ChromaDB
    logger.info("Adding documents to ChromaDB...")
    db.vector_db.add_documents(vector_chunks, embeddings)
    
    logger.info("\n" + "="*80)
    logger.info("✅ SUCCESS! pop2016.pdf processed and stored in ChromaDB")
    logger.info("="*80)
    logger.info(f"Total documents stored: {len(vector_chunks)}")
    logger.info(f"Collection: krishi_sakha_docs")
    logger.info(f"Database path: {project_root / 'chroma_db'}")
    logger.info("="*80)
    
    # Test search
    logger.info("\n🔍 TESTING SEARCH:")
    logger.info("-" * 80)
    
    test_queries = [
        "rice cultivation methods",
        "pepper vine removal timing",
        "fertilizer recommendations for crops",
        "coffee diseases management"
    ]
    
    for query in test_queries:
        logger.info(f"\nQuery: '{query}'")
        query_embedding = db.embedding_generator.generate_embeddings([query])[0]
        results = db.vector_db.search(query_embedding, n_results=2)
        
        if results['documents'][0]:
            for i, (doc, meta) in enumerate(zip(results['documents'][0], results['metadatas'][0]), 1):
                logger.info(f"  Result {i}:")
                logger.info(f"    Pages: {meta.get('start_page', '?')}-{meta.get('end_page', '?')}")
                logger.info(f"    Type: {meta.get('content_type', '?')}")
                preview = doc[:200].replace('\n', ' ')
                logger.info(f"    Text: {preview}...")
    
    logger.info("\n" + "="*80)
    logger.info("✅ All tests completed successfully!")
    logger.info("="*80)
    
except Exception as e:
    logger.error("\n" + "="*80)
    logger.error(f"❌ ERROR: {e}")
    logger.error("="*80)
    import traceback
    logger.error(traceback.format_exc())
