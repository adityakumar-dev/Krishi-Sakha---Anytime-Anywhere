import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import json
import os
import logging

logger = logging.getLogger(__name__)

# Initialize model (loads once at startup)
logger.info("Loading IndicTrans2 model...")
print("Loading IndicTrans2 model...")
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model_name = "ai4bharat/indictrans2-en-indic-dist-200M"

try:
    tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
    model = AutoModelForSeq2SeqLM.from_pretrained(model_name, trust_remote_code=True)
    model = model.to(device).eval()
    logger.info(f"✓ Model loaded on {device}")
    print(f"✓ Model loaded on {device}")
except Exception as e:
    logger.error(f"Failed to load model: {e}")
    print(f"✗ Failed to load model: {e}")
    raise

# Language codes
LANGUAGES = {
    'hi': 'hin_Deva',      # Hindi
    'bn': 'ben_Beng',      # Bengali
    'ta': 'tam_Taml',      # Tamil
    'te': 'tel_Telu',      # Telugu
    'mr': 'mar_Deva',      # Marathi
    'gu': 'guj_Gujr',      # Gujarati
    'kn': 'kan_Knda',      # Kannada
    'ml': 'mal_Mlym',      # Malayalam
    'pa': 'pan_Guru',      # Punjabi
    'ur': 'urd_Arab',      # Urdu
}

LANGUAGE_NAMES = {
    'hi': 'Hindi',
    'bn': 'Bengali',
    'ta': 'Tamil',
    'te': 'Telugu',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'pa': 'Punjabi',
    'ur': 'Urdu',
}


class LanguageTranslator:
    """Handles translation operations using IndicTrans2 model"""
    
    def __init__(self):
        self.device = device
        self.model = model
        self.tokenizer = tokenizer
        self.languages = LANGUAGES
        self.language_names = LANGUAGE_NAMES
    
    def translate(self, text: str, target_language: str) -> dict:
        """
        Translate English text to target Indian language
        
        Args:
            text (str): English text to translate
            target_language (str): Language code (hi, bn, ta, te, mr, gu, kn, ml, pa, ur)
        
        Returns:
            dict: Translation result with metadata
        """
        if not text or not text.strip():
            return {'error': 'Text is required', 'success': False}
        
        if target_language not in self.languages:
            return {
                'error': f'Invalid language. Supported: {list(self.languages.keys())}',
                'success': False
            }
        
        try:
            target_lang = self.languages[target_language]
            input_text = f"eng_Latn {target_lang} {text.strip()}"
            
            inputs = self.tokenizer(input_text, return_tensors="pt", padding=True).to(self.device)
            
            with torch.no_grad():
                outputs = self.model.generate(
                    **inputs,
                    max_length=256,
                    num_beams=1,
                    use_cache=False
                )
            
            translation = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
            
            return {
                'success': True,
                'original': text.strip(),
                'translation': translation,
                'language': target_language,
                'language_name': self.language_names.get(target_language, target_language)
            }
        
        except Exception as e:
            logger.error(f"Translation error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'original': text.strip()
            }
    
    def batch_translate(self, texts: list, target_language: str) -> dict:
        """
        Translate multiple texts at once
        
        Args:
            texts (list): List of English texts to translate
            target_language (str): Target language code
        
        Returns:
            dict: Batch translation results
        """
        if not texts:
            return {'error': 'Texts array is required', 'success': False}
        
        if target_language not in self.languages:
            return {
                'error': f'Invalid language. Supported: {list(self.languages.keys())}',
                'success': False
            }
        
        try:
            target_lang = self.languages[target_language]
            results = []
            
            for text in texts:
                text = text.strip()
                if not text:
                    continue
                
                input_text = f"eng_Latn {target_lang} {text}"
                inputs = self.tokenizer(input_text, return_tensors="pt", padding=True).to(self.device)
                
                with torch.no_grad():
                    outputs = self.model.generate(
                        **inputs,
                        max_length=256,
                        num_beams=1,
                        use_cache=False
                    )
                
                translation = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
                results.append({
                    'original': text,
                    'translation': translation
                })
            
            return {
                'success': True,
                'results': results,
                'language': target_language,
                'language_name': self.language_names.get(target_language, target_language),
                'count': len(results)
            }
        
        except Exception as e:
            logger.error(f"Batch translation error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'count': 0
            }
    
    def get_supported_languages(self) -> dict:
        """Get list of supported languages"""
        return {
            'languages': self.language_names,
            'codes': list(self.languages.keys()),
            'count': len(self.languages)
        }
    
    def get_health_status(self) -> dict:
        """Get health status of the translator"""
        return {
            'status': 'ok',
            'model': 'IndicTrans2',
            'device': str(self.device),
            'languages': list(self.languages.keys()),
            'language_count': len(self.languages)
        }


# Global translator instance
language_translator = LanguageTranslator()

