"""
Test and visualize content detection from pop2016.pdf
Shows what the parser detects before AI processing
"""

import os
import sys
from pathlib import Path

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from data.functions.enhanced_pdf_parser import EnhancedPDFParser
import logging

logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)


def visualize_content_detection():
    """
    Extract and visualize content blocks without AI processing
    """
    pdf_path = project_root / "data" / "pdfs" / "pop2016.pdf"
    
    if not pdf_path.exists():
        logger.error(f"PDF not found: {pdf_path}")
        return
    
    logger.info("="*80)
    logger.info("CONTENT DETECTION VISUALIZATION")
    logger.info("="*80)
    logger.info(f"PDF: {pdf_path.name}\n")
    
    try:
        # Initialize parser
        parser = EnhancedPDFParser(gemini_api_key=os.getenv("GEMINI_API_KEY"))
        
        # Extract with continuity
        logger.info("🔍 Analyzing PDF structure...\n")
        content_blocks = parser.extract_with_continuity(str(pdf_path))
        
        # Display results
        logger.info("\n" + "="*80)
        logger.info("DETECTED CONTENT BLOCKS")
        logger.info("="*80 + "\n")
        
        for i, block in enumerate(content_blocks, 1):
            logger.info(f"Block #{i}")
            logger.info(f"{'─'*80}")
            logger.info(f"Type:       {block.content_type.upper()}")
            logger.info(f"Pages:      {block.start_page} → {block.end_page}")
            logger.info(f"Page Span:  {block.end_page - block.start_page + 1} page(s)")
            is_multipage = block.end_page > block.start_page
            logger.info(f"Multi-page: {'✅ YES' if is_multipage else '❌ NO'}")
            
            # Show text preview
            text = block.get_combined_text()
            preview_length = 300
            
            if block.content_type == "table":
                logger.info(f"\n📊 TABLE PREVIEW:")
                # Show first few lines
                lines = text.split('\n')[:10]
                for line in lines:
                    if line.strip():
                        logger.info(f"   {line[:70]}")
                if len(text) > preview_length:
                    logger.info(f"   ... ({len(text)} total characters)")
            else:
                logger.info(f"\n📝 TEXT PREVIEW:")
                preview = text[:preview_length].replace('\n', ' ')
                logger.info(f"   {preview}...")
            
            logger.info(f"\n{'═'*80}\n")
        
        # Summary statistics
        logger.info("\n" + "="*80)
        logger.info("SUMMARY STATISTICS")
        logger.info("="*80)
        logger.info(f"Total blocks:        {len(content_blocks)}")
        logger.info(f"Tables:              {sum(1 for b in content_blocks if b.content_type == 'table')}")
        logger.info(f"Multi-page blocks:   {sum(1 for b in content_blocks if b.end_page > b.start_page)}")
        
        # Page span analysis
        multipage_blocks = [b for b in content_blocks if b.end_page > b.start_page]
        if multipage_blocks:
            logger.info(f"\n📄 Multi-page block details:")
            for block in multipage_blocks:
                span = block.end_page - block.start_page + 1
                logger.info(f"   • {block.content_type.capitalize()}: "
                          f"pages {block.start_page}-{block.end_page} ({span} pages)")
        
        logger.info("\n" + "="*80)
        logger.info("✅ Content detection complete!")
        logger.info("="*80)
        
    except Exception as e:
        logger.error(f"❌ Error: {e}")
        import traceback
        logger.error(traceback.format_exc())


if __name__ == "__main__":
    visualize_content_detection()
