"""
Quick test: Process only first 40 pages of pop2016.pdf
"""

import os
import sys
from pathlib import Path

# Set path to project root (parent of scripts folder)
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

import logging
from data.functions.enhanced_pdf_parser import EnhancedPDFParser
from data.functions.add_to_vector_db import PDFVectorDBManager

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

pdf_path = project_root / "data" / "pdfs" / "pop2016.pdf"

try:
    # Parse with Gemini AI
    logger.info("📖 Parsing first 40 pages...")
    parser = EnhancedPDFParser(gemini_api_key=os.getenv("GEMINI_API_KEY"))
    
    # Extract with page limit
    if True:
        import pdfplumber
        pdf = pdfplumber.open(pdf_path)
        pages = pdf.pages[:40]  # First 40 pages only
        
        # Extract text from pages
        content_blocks = []
        current_block = None
        for page_num, page in enumerate(pages, 1):
            text = page.extract_text() or ""
            if not text.strip():
                continue
            
            content_type = parser._detect_content_type(text)
            
            if current_block and current_block.content_type == content_type and page_num - current_block.end_page == 1:
                current_block.add_page_content(text, page_num)
            else:
                if current_block:
                    current_block.mark_complete()
                    content_blocks.append(current_block)
                
                from data.functions.enhanced_pdf_parser import ContentBlock
                current_block = ContentBlock(content_type, page_num)
                current_block.add_page_content(text, page_num)
        
        if current_block:
            current_block.mark_complete()
            content_blocks.append(current_block)
        
        pdf.close()
        
        logger.info(f"✅ Extracted {len(content_blocks)} content blocks from 40 pages")
        
        # Process with AI
        logger.info("\n🤖 Processing with Gemini AI...")
        chunks = []
        for i, block in enumerate(content_blocks, 1):
            result = parser.process_block_with_ai(block, "agricultural practices")
            chunk = {
                'text': result['processed_text'],
                'metadata': {
                    'start_page': result['start_page'],
                    'end_page': result['end_page'],
                    'content_type': result['content_type'],
                    'is_multipage': result['is_multipage'],
                    'source_file': pdf_path.name,
                    'ai_processed': result['success']
                }
            }
            chunks.append(chunk)
            logger.info(f"Processed {i}/{len(content_blocks)} blocks")
        
        logger.info(f"\n✅ Generated {len(chunks)} chunks")
        
        # Store in ChromaDB
        logger.info("\n💾 Storing in ChromaDB...")
        db = PDFVectorDBManager(db_path="./chroma_db", collection_name="krishi_sakha_docs")
        
        texts = [c['text'] for c in chunks]
        embeddings = db.embedding_generator.generate_embeddings(texts)
        
        # Add metadata properly
        vector_chunks = []
        for i, chunk in enumerate(chunks):
            v_chunk = {
                'text': chunk['text'],
                'metadata': chunk['metadata'],
                'chunk_index': i,
                'source_file': chunk['metadata']['source_file'],
                'file_hash': 'test_40pages',
                'created_at': '2025-12-07'
            }
            vector_chunks.append(v_chunk)
        
        db.vector_db.add_documents(vector_chunks, embeddings)
        logger.info(f"✅ Stored {len(vector_chunks)} documents in ChromaDB")
        
        # Test search
        logger.info("\n🔍 Testing search...")
        test_queries = [
            "rice cultivation",
            "fertilizer recommendations",
            "crop diseases"
        ]
        
        for query in test_queries:
            logger.info(f"\n  Query: '{query}'")
            embedding = db.embedding_generator.generate_embeddings([query])[0]
            results = db.vector_db.search(embedding, n_results=2)
            
            if results['documents'][0]:
                for j, doc in enumerate(results['documents'][0], 1):
                    preview = doc[:150].replace('\n', ' ')
                    logger.info(f"    Result {j}: {preview}...")
            else:
                logger.info(f"    No results")
        
        logger.info("\n" + "="*60)
        logger.info("✅ SUCCESS! Vector DB is working with 40 pages")
        logger.info("="*60)
        
except Exception as e:
    logger.error(f"❌ ERROR: {e}")
    import traceback
    logger.error(traceback.format_exc())
