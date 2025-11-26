"""
Tomato Disease Detection - Simple Prediction Script
"""

import os
import json
import numpy as np
import cv2
import tensorflow as tf

class TomatoPredictorTFLite:
    """Simple TFLite inference for tomato disease detection"""
    
    def __init__(self, model_path='output/tomato_model.tflite', 
                 classes_path='output/classes.json'):
        self.model_path = model_path
        self.img_size = 256
        
        # Load model
        self.interpreter = tf.lite.Interpreter(model_path=model_path)
        self.interpreter.allocate_tensors()
        
        self.input_details = self.interpreter.get_input_details()
        self.output_details = self.interpreter.get_output_details()
        
        # Load classes
        with open(classes_path, 'r') as f:
            self.classes = json.load(f)
        
        print(f"✓ Model loaded: {model_path}")
        print(f"✓ Classes loaded: {len(self.classes)} diseases")
    
    def predict(self, image_path):
        """Predict disease from image"""
        # Read image
        img = cv2.imread(image_path)
        if img is None:
            return {'error': f'Could not read image: {image_path}'}
        
        # Resize
        img = cv2.resize(img, (self.img_size, self.img_size))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = img.astype(np.float32) / 255.0
        img = np.expand_dims(img, axis=0)
        
        # Predict
        self.interpreter.set_tensor(self.input_details[0]['index'], img)
        self.interpreter.invoke()
        output_data = self.interpreter.get_tensor(self.output_details[0]['index'])
        
        predictions = output_data[0]
        top_idx = np.argmax(predictions)
        top_prob = predictions[top_idx]
        
        disease = self.classes[str(top_idx)]
        confidence = float(top_prob) * 100
        
        return {
            'disease': disease,
            'confidence': f'{confidence:.2f}%',
            'probability': float(top_prob)
        }

class TomatoPredictorH5:
    """Simple H5 inference for tomato disease detection"""
    
    def __init__(self, model_path='output/tomato_model.h5',
                 classes_path='output/classes.json'):
        self.model = tf.keras.models.load_model(model_path)
        self.img_size = 256
        
        with open(classes_path, 'r') as f:
            self.classes = json.load(f)
        
        print(f"✓ Model loaded: {model_path}")
        print(f"✓ Classes loaded: {len(self.classes)} diseases")
    
    def predict(self, image_path):
        """Predict disease from image"""
        # Read image
        img = cv2.imread(image_path)
        if img is None:
            return {'error': f'Could not read image: {image_path}'}
        
        # Resize
        img = cv2.resize(img, (self.img_size, self.img_size))
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = img.astype(np.float32) / 255.0
        img = np.expand_dims(img, axis=0)
        
        # Predict
        predictions = self.model.predict(img, verbose=0)[0]
        top_idx = np.argmax(predictions)
        top_prob = predictions[top_idx]
        
        disease = self.classes[str(top_idx)]
        confidence = float(top_prob) * 100
        
        return {
            'disease': disease,
            'confidence': f'{confidence:.2f}%',
            'probability': float(top_prob)
        }

def main():
    """Predict disease with flexible argument parsing"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Tomato Disease Detection - Inference',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python predict.py /path/to/image.jpg                                 # Use default TFLite model
  python predict.py /path/to/image.jpg h5                              # Use H5 model
  python predict.py --image-path /path/to/image.jpg --model-path output/tomato_model.h5
        """
    )
    parser.add_argument(
        'image_path',
        nargs='?',
        default=None,
        help='Path to the image file'
    )
    parser.add_argument(
        'model_type',
        nargs='?',
        default='tflite',
        help="Model type: 'tflite' (default, faster) or 'h5' (better accuracy)"
    )
    parser.add_argument(
        '--image-path',
        dest='image_path_arg',
        default=None,
        help='Path to the image file (overrides positional argument)'
    )
    parser.add_argument(
        '--model-path',
        dest='model_path_arg',
        default=None,
        help='Path to the model file (overrides model_type)'
    )
    parser.add_argument(
        '--classes-path',
        default='output/classes.json',
        help='Path to the classes.json file'
    )
    
    args = parser.parse_args()
    
    # Determine image path (prefer --image-path)
    image_path = args.image_path_arg or args.image_path
    
    if image_path is None:
        parser.print_help()
        return
    
    # Determine model path
    if args.model_path_arg:
        model_path = args.model_path_arg
        model_type = 'h5' if model_path.endswith('.h5') else 'tflite'
    else:
        model_type = args.model_type
        model_path = 'output/tomato_model.h5' if model_type == 'h5' else 'output/tomato_model.tflite'
    
    print(f"🔍 Predicting disease for: {image_path}")
    
    if model_type == 'h5':
        predictor = TomatoPredictorH5(model_path, args.classes_path)
    else:
        predictor = TomatoPredictorTFLite(model_path, args.classes_path)
    
    result = predictor.predict(image_path)
    
    print(f"\n{'='*40}")
    print(f"🌱 TOMATO DISEASE DETECTION")
    print(f"{'='*40}")
    if 'error' in result:
        print(f"❌ {result['error']}")
    else:
        print(f"Disease: {result['disease']}")
        print(f"Confidence: {result['confidence']}")
        print(f"{'='*40}")

if __name__ == '__main__':
    main()
