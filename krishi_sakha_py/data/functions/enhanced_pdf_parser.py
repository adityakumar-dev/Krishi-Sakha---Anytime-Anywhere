"""
Enhanced PDF Parser with Multi-Page Content Continuity
Handles:
1. Paragraphs spanning multiple pages
2. Tables spanning multiple pages
3. Proper context preservation with Gemini AI
4. Parallel processing with multiple API keys
"""

import os
import logging
import time
from typing import List, Dict, Optional, Union, Tuple
from pathlib import Path
import hashlib
from datetime import datetime
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False

try:
    import pdfplumber
    PDFPLUMBER_AVAILABLE = True
except ImportError:
    PDFPLUMBER_AVAILABLE = False

try:
    import PyPDF2
    PYPDF2_AVAILABLE = True
except ImportError:
    PYPDF2_AVAILABLE = False

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class ContentBlock:
    """Represents a continuous block of content (paragraph or table) across pages"""
    
    def __init__(self, content_type: str, start_page: int):
        self.content_type = content_type  # "paragraph" or "table"
        self.start_page = start_page
        self.end_page = start_page
        self.pages_text = []
        self.is_complete = False
        
    def add_page_content(self, text: str, page_num: int):
        """Add content from a page"""
        self.pages_text.append({
            'page': page_num,
            'text': text
        })
        self.end_page = page_num
    
    def get_combined_text(self) -> str:
        """Get all text combined"""
        return "\n".join([p['text'] for p in self.pages_text])
    
    def mark_complete(self):
        """Mark this block as complete"""
        self.is_complete = True


class EnhancedPDFParser:
    """
    Enhanced PDF parser that handles multi-page content continuity
    Supports multiple API keys for parallel processing
    """
    
    def __init__(self, gemini_api_key: str = None, api_keys: List[str] = None):
        if not GEMINI_AVAILABLE:
            raise ImportError("google-generativeai package not available")
        
        # Support multiple API keys
        self.api_keys = api_keys or []
        if not self.api_keys and gemini_api_key:
            self.api_keys = [gemini_api_key]
        if not self.api_keys:
            single_key = os.getenv("GEMINI_API_KEY")
            if single_key:
                self.api_keys = [single_key]
        
        if not self.api_keys:
            raise ValueError("Gemini API key(s) required for enhanced parsing")
        
        self.current_key_idx = 0
        genai.configure(api_key=self.api_keys[0])
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        logger.info(f"Initialized Enhanced PDF Parser with {len(self.api_keys)} API key(s)")
    
    def _get_next_api_key(self) -> str:
        """Round-robin through API keys"""
        key = self.api_keys[self.current_key_idx]
        self.current_key_idx = (self.current_key_idx + 1) % len(self.api_keys)
        return key
    
    def _switch_api_key(self):
        """Switch to next API key for load balancing"""
        next_key = self._get_next_api_key()
        genai.configure(api_key=next_key)
    
    def _detect_content_type(self, text: str) -> str:
        """
        Detect if text is likely a table, paragraph, or mixed
        
        Returns:
            "table", "paragraph", or "mixed"
        """
        if not text or len(text.strip()) < 20:
            return "unknown"
        
        # Count indicators
        lines = text.split('\n')
        num_lines = len([l for l in lines if l.strip()])
        digits = sum(c.isdigit() for c in text)
        total_chars = len(text.replace('\n', '').replace(' ', ''))
        
        # Table indicators
        has_many_numbers = digits > 30 and total_chars > 0 and (digits / total_chars) > 0.15
        has_many_short_lines = num_lines > 8 and sum(len(l.strip()) < 50 for l in lines) > num_lines * 0.6
        has_pipe_symbols = text.count('|') > 5
        has_tab_chars = text.count('\t') > 5
        
        # Check for table headers patterns
        table_keywords = ['total', 'year', 'state', 'district', 'male', 'female', 'population', 
                         'count', 'number', 'percent', '%', 'average', 'sum']
        has_table_keywords = sum(keyword in text.lower() for keyword in table_keywords) >= 2
        
        if (has_many_numbers and has_many_short_lines) or has_pipe_symbols or (has_tab_chars and has_many_numbers):
            return "table"
        elif has_table_keywords and has_many_numbers:
            return "table"
        else:
            return "paragraph"
    
    def _is_content_continuing(self, current_text: str, previous_text: str) -> bool:
        """
        Detect if content continues from previous page
        
        Checks:
        - Incomplete sentence at end of previous page
        - Similar content type
        - No major heading/section break
        """
        if not previous_text or not current_text:
            return False
        
        prev_last_line = previous_text.strip().split('\n')[-1].strip()
        current_first_line = current_text.strip().split('\n')[0].strip()
        
        # Check for sentence continuation (ends without period, comma, etc.)
        incomplete_sentence = prev_last_line and prev_last_line[-1] not in ['.', '!', '?', ':', ';']
        
        # Check for table continuation (similar structure)
        prev_type = self._detect_content_type(previous_text[-500:])  # Last 500 chars
        curr_type = self._detect_content_type(current_text[:500])  # First 500 chars
        same_content_type = prev_type == curr_type
        
        # Check for explicit page breaks / new sections
        section_markers = ['chapter', 'section', 'part', 'appendix', 'table of contents', 'index']
        has_section_break = any(marker in current_first_line.lower() for marker in section_markers)
        
        # Check if current starts with lowercase (likely continuation)
        starts_lowercase = current_first_line and current_first_line[0].islower()
        
        return (incomplete_sentence or same_content_type or starts_lowercase) and not has_section_break
    
    def extract_with_continuity(self, pdf_path: str) -> List[ContentBlock]:
        """
        Extract content with multi-page continuity detection
        
        Returns:
            List of ContentBlock objects representing continuous content
        """
        if not PDFPLUMBER_AVAILABLE and not PYPDF2_AVAILABLE:
            raise ImportError("Either pdfplumber or PyPDF2 required")
        
        logger.info(f"📖 Extracting content with continuity detection from: {pdf_path}")
        
        content_blocks = []
        current_block = None
        previous_page_text = None
        
        # Open PDF with pdfplumber (preferred) or PyPDF2
        if PDFPLUMBER_AVAILABLE:
            pdf = pdfplumber.open(pdf_path)
            pages = pdf.pages
            total_pages = len(pages)
        else:
            pdf = PyPDF2.PdfReader(pdf_path)
            pages = pdf.pages
            total_pages = len(pages)
        
        logger.info(f"Processing {total_pages} pages...")
        
        for page_num in range(total_pages):
            # Extract text from page
            if PDFPLUMBER_AVAILABLE:
                page_text = pages[page_num].extract_text() or ""
            else:
                page_text = pages[page_num].extract_text() or ""
            
            if not page_text.strip():
                continue
            
            # Detect content type
            content_type = self._detect_content_type(page_text)
            
            # Check if continuing from previous page
            is_continuing = False
            if current_block and previous_page_text:
                is_continuing = self._is_content_continuing(page_text, previous_page_text)
            
            # Decide: continue current block or start new one
            if is_continuing and current_block and current_block.content_type == content_type:
                # Continue existing block
                current_block.add_page_content(page_text, page_num + 1)
                logger.debug(f"Page {page_num + 1}: Continuing {content_type} (started on page {current_block.start_page})")
            else:
                # Complete previous block and start new one
                if current_block:
                    current_block.mark_complete()
                    content_blocks.append(current_block)
                
                # Start new block
                current_block = ContentBlock(content_type, page_num + 1)
                current_block.add_page_content(page_text, page_num + 1)
                logger.debug(f"Page {page_num + 1}: Starting new {content_type} block")
            
            previous_page_text = page_text
            
            # Progress indicator
            if (page_num + 1) % 10 == 0:
                logger.info(f"Processed {page_num + 1}/{total_pages} pages...")
        
        # Complete the last block
        if current_block:
            current_block.mark_complete()
            content_blocks.append(current_block)
        
        if PDFPLUMBER_AVAILABLE:
            pdf.close()
        
        logger.info(f"✅ Extracted {len(content_blocks)} content blocks with continuity")
        
        # Summary
        tables = [b for b in content_blocks if b.content_type == "table"]
        paragraphs = [b for b in content_blocks if b.content_type == "paragraph"]
        logger.info(f"   - Tables: {len(tables)}")
        logger.info(f"   - Paragraphs: {len(paragraphs)}")
        logger.info(f"   - Multi-page blocks: {sum(1 for b in content_blocks if b.end_page > b.start_page)}")
        
        return content_blocks
    
    def process_block_with_ai(self, block: ContentBlock, document_context: str = "") -> Dict:
        """
        Process a content block with Gemini AI
        
        For tables: Converts to natural language statements
        For paragraphs: Cleans and summarizes if needed
        """
        combined_text = block.get_combined_text()
        
        if block.content_type == "table":
            prompt = f"""
You are analyzing a table from a PDF document{f" about {document_context}" if document_context else ""}.

This table spans from page {block.start_page} to page {block.end_page}.

TABLE CONTENT:
{combined_text[:4000]}  

TASK:
1. Identify the table structure (column headers, row labels)
2. Convert each row into clear, factual statements
3. Preserve all numerical values exactly
4. If the table is incomplete, note which parts are missing

FORMAT YOUR RESPONSE AS:
### Table Summary
[Brief description of what this table shows]

### Column Headers
[List the column headers]

### Data Statements
[Convert each row to natural language]
- Example: "In 2016, Delhi had a population of 16,753,235"

### Additional Context
[Any important notes about the table]
"""
        else:  # paragraph
            prompt = f"""
You are analyzing text from a PDF document{f" about {document_context}" if document_context else ""}.

This text spans from page {block.start_page} to page {block.end_page}.

TEXT CONTENT:
{combined_text[:4000]}

TASK:
1. Clean up any OCR errors or formatting issues
2. Preserve all factual information
3. Maintain the original meaning
4. If text seems incomplete, note what might be missing

Provide the cleaned text:
"""
        
        try:
            logger.info(f"🤖 Processing {block.content_type} block (pages {block.start_page}-{block.end_page}) with AI...")
            # Switch API key for load balancing
            if len(self.api_keys) > 1:
                self._switch_api_key()
            
            response = self.model.generate_content(prompt)
            processed_text = response.text
            
            # Adaptive rate limiting based on number of keys
            delay = max(0.5, 2.0 / len(self.api_keys))
            time.sleep(delay)
            
            return {
                'original_text': combined_text,
                'processed_text': processed_text,
                'content_type': block.content_type,
                'start_page': block.start_page,
                'end_page': block.end_page,
                'is_multipage': block.end_page > block.start_page,
                'success': True
            }
        except Exception as e:
            logger.error(f"AI processing failed for block: {e}")
            return {
                'original_text': combined_text,
                'processed_text': combined_text,  # Fallback to original
                'content_type': block.content_type,
                'start_page': block.start_page,
                'end_page': block.end_page,
                'is_multipage': block.end_page > block.start_page,
                'success': False,
                'error': str(e)
            }
    
    def _process_blocks_serial(self, 
                               content_blocks: List,
                               pdf_path: str,
                               document_context: str,
                               organization: str,
                               document_type: str,
                               document_category: str,
                               year: str) -> List[Dict]:
        """Sequential block processing"""
        processed_chunks = []
        for i, block in enumerate(content_blocks):
            logger.info(f"Processing block {i+1}/{len(content_blocks)}...")
            result = self.process_block_with_ai(block, document_context)
            
            chunk = {
                'text': result['processed_text'],
                'metadata': {
                    'source_file': os.path.basename(pdf_path),
                    'chunk_index': i,
                    'content_type': result['content_type'],
                    'start_page': result['start_page'],
                    'end_page': result['end_page'],
                    'is_multipage': result['is_multipage'],
                    'page_span': result['end_page'] - result['start_page'] + 1,
                    'organization': organization,
                    'document_type': document_type,
                    'document_category': document_category,
                    'publication_year': year,
                    'extraction_method': 'enhanced_continuity_ai',
                    'ai_processed': result['success'],
                    'created_at': datetime.now().isoformat(),
                    'file_hash': self._generate_file_hash(pdf_path),
                    'original_text_length': len(result['original_text']),
                    'processed_text_length': len(result['processed_text'])
                }
            }
            
            if not result['success']:
                chunk['metadata']['error'] = result.get('error', 'Unknown error')
            
            processed_chunks.append(chunk)
        return processed_chunks
    
    def _process_blocks_parallel(self, 
                                 content_blocks: List,
                                 pdf_path: str,
                                 document_context: str,
                                 organization: str,
                                 document_type: str,
                                 document_category: str,
                                 year: str,
                                 max_workers: int = 3) -> List[Dict]:
        """Parallel block processing with multiple API keys"""
        def process_block_wrapper(block_index_tuple):
            i, block = block_index_tuple
            logger.info(f"Processing block {i+1}/{len(content_blocks)}...")
            result = self.process_block_with_ai(block, document_context)
            
            chunk = {
                'text': result['processed_text'],
                'metadata': {
                    'source_file': os.path.basename(pdf_path),
                    'chunk_index': i,
                    'content_type': result['content_type'],
                    'start_page': result['start_page'],
                    'end_page': result['end_page'],
                    'is_multipage': result['is_multipage'],
                    'page_span': result['end_page'] - result['start_page'] + 1,
                    'organization': organization,
                    'document_type': document_type,
                    'document_category': document_category,
                    'publication_year': year,
                    'extraction_method': 'enhanced_continuity_ai',
                    'ai_processed': result['success'],
                    'created_at': datetime.now().isoformat(),
                    'file_hash': self._generate_file_hash(pdf_path),
                    'original_text_length': len(result['original_text']),
                    'processed_text_length': len(result['processed_text'])
                }
            }
            
            if not result['success']:
                chunk['metadata']['error'] = result.get('error', 'Unknown error')
            
            return (i, chunk)
        
        processed_chunks = [None] * len(content_blocks)
        
        with ThreadPoolExecutor(max_workers=min(max_workers, len(self.api_keys))) as executor:
            futures = {executor.submit(process_block_wrapper, (i, block)): i 
                      for i, block in enumerate(content_blocks)}
            
            for future in as_completed(futures):
                try:
                    idx, chunk = future.result()
                    processed_chunks[idx] = chunk
                except Exception as e:
                    logger.error(f"Parallel processing error: {e}")
        
        return processed_chunks

    def parse_pdf_with_continuity(self, 
                                  pdf_path: str,
                                  document_context: str = "",
                                  organization: str = "Unknown",
                                  document_type: str = "Unknown",
                                  document_category: str = "General",
                                  year: str = "Unknown",
                                  parallel: bool = False) -> List[Dict]:
        """
        Complete pipeline: Extract with continuity + Process with AI
        
        Args:
            pdf_path: Path to PDF file
            document_context: Brief description (e.g., "population statistics")
            organization: Organization name
            document_type: Document type
            document_category: Category
            year: Publication year
            parallel: Use parallel processing for faster API calls
            
        Returns:
            List of processed chunks ready for vector DB
        """
        logger.info(f"🚀 Starting enhanced parsing for: {pdf_path}")
        logger.info(f"Using {'PARALLEL' if parallel and len(self.api_keys) > 1 else 'SERIAL'} processing")
        
        # Step 1: Extract with continuity
        content_blocks = self.extract_with_continuity(pdf_path)
        
        # Step 2: Process each block with AI
        if parallel and len(self.api_keys) > 1:
            processed_chunks = self._process_blocks_parallel(
                content_blocks, pdf_path, document_context,
                organization, document_type, document_category, year
            )
        else:
            processed_chunks = self._process_blocks_serial(
                content_blocks, pdf_path, document_context,
                organization, document_type, document_category, year
            )
        
        logger.info(f"✅ Generated {len(processed_chunks)} chunks from {len(content_blocks)} content blocks")
        return processed_chunks
    
    def _generate_file_hash(self, file_path: str) -> str:
        """Generate MD5 hash of file"""
        hash_md5 = hashlib.md5()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()


# Convenience function
def parse_pdf_enhanced(pdf_path: str,
                      document_context: str = "",
                      organization: str = "Unknown",
                      document_type: str = "Unknown",
                      document_category: str = "General",
                      year: str = "Unknown",
                      api_keys: List[str] = None,
                      parallel: bool = False,
                      gemini_api_key: str = None) -> List[Dict]:
    """
    Parse PDF with enhanced multi-page continuity handling
    
    Example:
        chunks = parse_pdf_enhanced(
            "pop2016.pdf",
            document_context="population statistics of India",
            organization="Census Bureau",
            year="2016",
            api_keys=["key1", "key2", "key3"],
            parallel=True
        )
    """
    parser = EnhancedPDFParser(api_keys=api_keys or [gemini_api_key], gemini_api_key=gemini_api_key)
    return parser.parse_pdf_with_continuity(
        pdf_path=pdf_path,
        document_context=document_context,
        organization=organization,
        document_type=document_type,
        document_category=document_category,
        year=year,
        parallel=parallel and len(api_keys or []) > 1
    )


if __name__ == "__main__":
    # Example usage
    print("Enhanced PDF Parser initialized!")
    print("\nFeatures:")
    print("✅ Multi-page paragraph tracking")
    print("✅ Multi-page table handling")
    print("✅ AI-powered table conversion")
    print("✅ Content continuity detection")
    print("\nUsage:")
    print("from data.functions.enhanced_pdf_parser import parse_pdf_enhanced")
    print("chunks = parse_pdf_enhanced('your_file.pdf', document_context='your context')")
