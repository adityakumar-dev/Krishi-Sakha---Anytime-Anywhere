"""
IndicTrans2 Translation Server with Caching
For offline-ready Flutter mobile app
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import json
import os
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Initialize model (loads once at startup)
print("Loading IndicTrans2 model...")
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model_name = "ai4bharat/indictrans2-en-indic-dist-200M"
tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForSeq2SeqLM.from_pretrained(model_name, trust_remote_code=True)
model = model.to(device).eval()
print(f"✓ Model loaded on {device}")

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

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'model': 'IndicTrans2',
        'device': str(device),
        'languages': list(LANGUAGES.keys())
    })

@app.route('/translate', methods=['POST'])
def translate():
    """
    Translate English text to Indian language
    
    Request JSON:
    {
        "text": "Hello",
        "language": "hi",  # Language code (hi, bn, ta, te, mr, gu, kn, ml, pa, ur)
    }
    
    Response JSON:
    {
        "success": true,
        "original": "Hello",
        "translation": "नमस्कार",
        "language": "Hindi",
        "timestamp": "2025-11-05T08:20:00"
    }
    """
    try:
        data = request.json
        text = data.get('text', '').strip()
        lang_code = data.get('language', 'hi').lower()
        
        # Validate input
        if not text:
            return jsonify({'error': 'Text is required'}), 400
        
        if lang_code not in LANGUAGES:
            return jsonify({'error': f'Invalid language. Supported: {list(LANGUAGES.keys())}'}), 400
        
        # Translate
        target_lang = LANGUAGES[lang_code]
        input_text = f"eng_Latn {target_lang} {text}"
        
        inputs = tokenizer(input_text, return_tensors="pt", padding=True).to(device)
        
        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=256,
                num_beams=1,
                use_cache=False
            )
        
        translation = tokenizer.decode(outputs[0], skip_special_tokens=True)
        
        return jsonify({
            'success': True,
            'original': text,
            'translation': translation,
            'language': lang_code,
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/batch-translate', methods=['POST'])
def batch_translate():
    """
    Translate multiple texts at once
    
    Request JSON:
    {
        "texts": ["Hello", "Good morning", "Thank you"],
        "language": "hi"
    }
    
    Response JSON:
    {
        "success": true,
        "results": [
            {"original": "Hello", "translation": "नमस्कार"},
            {"original": "Good morning", "translation": "शुभ सकाल"},
            {"original": "Thank you", "translation": "धन्यवाद"}
        ]
    }
    """
    try:
        data = request.json
        texts = data.get('texts', [])
        lang_code = data.get('language', 'hi').lower()
        
        if not texts:
            return jsonify({'error': 'Texts array is required'}), 400
        
        if lang_code not in LANGUAGES:
            return jsonify({'error': f'Invalid language. Supported: {list(LANGUAGES.keys())}'}), 400
        
        target_lang = LANGUAGES[lang_code]
        results = []
        
        for text in texts:
            text = text.strip()
            if not text:
                continue
            
            input_text = f"eng_Latn {target_lang} {text}"
            inputs = tokenizer(input_text, return_tensors="pt", padding=True).to(device)
            
            with torch.no_grad():
                outputs = model.generate(
                    **inputs,
                    max_length=256,
                    num_beams=1,
                    use_cache=False
                )
            
            translation = tokenizer.decode(outputs[0], skip_special_tokens=True)
            results.append({
                'original': text,
                'translation': translation
            })
        
        return jsonify({
            'success': True,
            'results': results,
            'language': lang_code,
            'count': len(results)
        })
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return jsonify({'error': str(e), 'success': False}), 500

@app.route('/languages', methods=['GET'])
def get_languages():
    """Get list of supported languages"""
    return jsonify({
        'languages': {
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
    })

if __name__ == '__main__':
    print("\n" + "="*60)
    print("IndicTrans2 Translation Server")
    print("="*60)
    print(f"Server running on http://0.0.0.0:5000")
    print(f"Device: {device}")
    print(f"Supported languages: {list(LANGUAGES.values())}")
    print("\nEndpoints:")
    print("  GET  /health")
    print("  POST /translate")
    print("  POST /batch-translate")
    print("  GET  /languages")
    print("="*60 + "\n")
    
    # Run server
    app.run(host='0.0.0.0', port=5000, debug=False)
