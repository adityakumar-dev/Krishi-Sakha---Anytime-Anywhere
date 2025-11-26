"""
IndicTrans2 Language Translation Routes
For FastAPI application - Indian language translation support
"""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import logging

from brain.language_brain import language_translator, LANGUAGE_NAMES

logger = logging.getLogger(__name__)
router = APIRouter()


# Request/Response Models
class TranslateRequest(BaseModel):
    """Request model for single text translation"""
    text: str
    language: str = "hi"  # Default to Hindi


class BatchTranslateRequest(BaseModel):
    """Request model for batch translation"""
    texts: List[str]
    language: str = "hi"


class LanguageInfo(BaseModel):
    """Language information model"""
    code: str
    name: str


# Endpoints
@router.get("/languages")
async def get_supported_languages():
    """
    Get list of supported Indian languages
    
    Returns:
    {
        "success": true,
        "languages": [
            {"code": "hi", "name": "Hindi"},
            {"code": "bn", "name": "Bengali"},
            ...
        ],
        "count": 10
    }
    """
    try:
        result = language_translator.get_supported_languages()
        # Convert to list format if it's a dict
        languages = result.get('languages', {})
        if isinstance(languages, dict):
            lang_list = [{"code": code, "name": name} for code, name in languages.items()]
        else:
            lang_list = languages
        
        return {
            "success": True,
            "languages": lang_list,
            "count": len(lang_list)
        }
    except Exception as e:
        logger.error(f"Error fetching languages: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/language-health")
async def language_health():
    """
    Health check for language translation service
    
    Returns:
    {
        "status": "ok",
        "model": "IndicTrans2",
        "device": "cpu/cuda",
        "language_count": 10
    }
    """
    try:
        status = language_translator.get_health_status()
        return status
    except Exception as e:
        logger.error(f"Error getting health status: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/translate")
async def translate(request: TranslateRequest):
    """
    Translate English text to Indian language
    
    Request:
    {
        "text": "Hello, how are you?",
        "language": "hi"  # hi, bn, ta, te, mr, gu, kn, ml, pa, ur
    }
    
    Response:
    {
        "success": true,
        "original": "Hello, how are you?",
        "translation": "नमस्ते, आप कैसे हैं?",
        "language": "hi",
        "language_name": "Hindi"
    }
    """
    try:
        # Validate input
        if not request.text or not request.text.strip():
            raise HTTPException(status_code=400, detail="Text is required")
        

        
        if request.language not in LANGUAGE_NAMES.keys():
            raise HTTPException(
                status_code=400,
                detail=f"Invalid language. Supported: {list(LANGUAGE_NAMES.keys())}"
            )
        print(request.language)
        # Translate using the brain module
        result = language_translator.translate(request.text, request.language)
        
        if not result.get('success'):
            raise HTTPException(status_code=400, detail=result.get('error', 'Translation failed'))
        print(result)
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Translation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/batch-translate")
async def batch_translate(request: BatchTranslateRequest):
    """
    Translate multiple English texts to Indian language
    
    Request:
    {
        "texts": ["Hello", "Good morning", "Thank you"],
        "language": "hi"
    }
    
    Response:
    {
        "success": true,
        "results": [
            {"original": "Hello", "translation": "नमस्कार"},
            {"original": "Good morning", "translation": "शुभ सकाल"},
            {"original": "Thank you", "translation": "धन्यवाद"}
        ],
        "language": "hi",
        "language_name": "Hindi",
        "count": 3
    }
    """
    try:
        # Validate input
        if not request.texts:
            raise HTTPException(status_code=400, detail="Texts array is required")
        
        if request.language not in LANGUAGE_NAMES.keys():
            raise HTTPException(
                status_code=400,
                detail=f"Invalid language. Supported: {list(LANGUAGE_NAMES.keys())}"
            )
        
        # Translate using the brain module
        result = language_translator.batch_translate(request.texts, request.language)
        
        if not result.get('success'):
            raise HTTPException(status_code=400, detail=result.get('error', 'Batch translation failed'))
        print(result)
        
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Batch translation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/translate-with-context")
async def translate_with_context(
    text: str,
    language: str = "hi",
    context: Optional[str] = None
):
    """
    Translate text with optional context for better accuracy
    
    Query parameters:
        text: Text to translate
        language: Target language code
        context: Optional context for better translation
    
    Returns translation result
    """
    try:
        if not text or not text.strip():
            raise HTTPException(status_code=400, detail="Text is required")
        
        if language not in LANGUAGE_NAMES.keys():
            raise HTTPException(
                status_code=400,
                detail=f"Invalid language. Supported: {list(LANGUAGE_NAMES.keys())}"
            )
        
        # Use context if provided
        if context:
            combined_text = f"{context}\n{text}"
        else:
            combined_text = text
        
        result = language_translator.translate(combined_text, language)
        
        if not result.get('success'):
            raise HTTPException(status_code=400, detail=result.get('error', 'Translation failed'))
        
        return result
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Context translation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))