"""
IndicTrans2 Translation Model - Fixed Demo
Uses use_cache=False to avoid past_key_values bug
"""

import torch
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM


class IndicTrans2:
    def __init__(self):
        self.model_name = "ai4bharat/indictrans2-en-indic-dist-200M"
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.model = None
        self.tokenizer = None
        self.load_model()
    
    def load_model(self):
        print(f"Loading model on {self.device}...")
        self.tokenizer = AutoTokenizer.from_pretrained(
            self.model_name, trust_remote_code=True
        )
        self.model = AutoModelForSeq2SeqLM.from_pretrained(
            self.model_name, trust_remote_code=True
        )
        self.model = self.model.to(self.device).eval()
        print("✓ Model loaded!")
    
    def translate(self, text, source_lang='eng_Latn', target_lang='hin_Deva', max_length=256):
        if not text.strip():
            return ""
        
        input_text = f"{source_lang} {target_lang} {text}"
        inputs = self.tokenizer(input_text, return_tensors="pt", padding=True).to(self.device)
        
        with torch.no_grad():
            # Use use_cache=False to avoid past_key_values bug
            outputs = self.model.generate(
                **inputs, 
                max_length=max_length, 
                num_beams=1,
                use_cache=False
            )
        
        return self.tokenizer.decode(outputs[0], skip_special_tokens=True)


def main():
    try:
        translator = IndicTrans2()
    except Exception as e:
        print(f"Error loading model: {e}")
        return
    
    print("\n" + "="*60)
    print("IndicTrans2 Translation Model - Working!")
    print("="*60)
    
    examples = [
        ("Hello", 'eng_Latn', 'hin_Deva', 'Hindi'),
        ("Good morning", 'eng_Latn', 'ben_Beng', 'Bengali'),
        ("Thank you", 'eng_Latn', 'tam_Taml', 'Tamil'),
        ("Hello how are you", 'eng_Latn', 'tel_Telu', 'Telugu'),
    ]
    
    for text, src, tgt, lang in examples:
        try:
            translation = translator.translate(text, src, tgt, max_length=128)
            print(f"\n📝 English: {text}")
            print(f"✓ {lang}: {translation}")
        except Exception as e:
            print(f"\n📝 English: {text}")
            print(f"✗ Error: {str(e)[:80]}")
    
    print("\n" + "="*60)
    print("✅ Translation demo completed!")
    print("="*60)


if __name__ == "__main__":
    main()
