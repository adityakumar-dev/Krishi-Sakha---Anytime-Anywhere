import os
import tensorflow as tf
from transformers import TFMarianMTModel, AutoTokenizer
import numpy as np

# Model details
model_name = "Helsinki-NLP/opus-mt-en-ml"
tokenizer = AutoTokenizer.from_pretrained(model_name)

# Load TF model (downloads ~230MB .h5 if not cached)
print("Loading model...")
model = TFMarianMTModel.from_pretrained(model_name, from_pt=True)  # Converts PT to TF if needed

# Generate representative dataset for full quantization (100 samples; use real translation data for better accuracy)
def representative_dataset_gen():
    for _ in range(100):
        # Dummy English sentences (replace with real agri queries for your app, e.g., from Kaggle)
        text = "The banana leaf has spots from pests. What fertilizer to use?"
        inputs = tokenizer(text, return_tensors="tf", padding=True, truncation=True, max_length=128)
        yield [inputs['input_ids']]

# Convert to TFLite with post-training quantization
print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]  # Enables dynamic range quantization
converter.representative_dataset = representative_dataset_gen  # For full int8 quantization (smaller, but needs dataset)
converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS_INT8,  # Allow int8 ops for max compression
    tf.lite.OpsSet.TFLITE_BUILTINS
]
converter.inference_input_type = tf.int8  # Quantize inputs
converter.inference_output_type = tf.int8  # Quantize outputs

tflite_model = converter.convert()

# Save
with open('opus_en_ml_quant.tflite', 'wb') as f:
    f.write(tflite_model)

# Size check
original_size = os.path.getsize('opus-mt-en-ml_tf_model.h5') / (1024 * 1024) if os.path.exists('opus-mt-en-ml_tf_model.h5') else 230
quant_size = len(tflite_model) / (1024 * 1024)
print(f"Original size: {original_size:.1f} MB")
print(f"Quantized TFLite size: {quant_size:.1f} MB")
print(f"Reduction: {((original_size - quant_size) / original_size * 100):.1f}%")