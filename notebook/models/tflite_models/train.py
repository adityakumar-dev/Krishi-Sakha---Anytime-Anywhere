"""
Tomato Disease Detection - Simple Training Script
High accuracy model using DenseNet121 transfer learning (94%+ accuracy)
Based on proven architecture from tomato-leaf-disease-94-accuracy.ipynb

Usage:
    python train.py                          # Uses ./tomatoleaf/tomato/ directory
    python train.py /path/to/tomato/data     # Custom path with train/ and val/ folders
"""

import os
import sys
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers, callbacks
from tensorflow.keras.applications import DenseNet121
from tensorflow.keras.preprocessing.image import ImageDataGenerator
import matplotlib.pyplot as plt
from pathlib import Path

# Default paths
DEFAULT_DATA_DIR = './tomatoleaf/tomato'
OUTPUT_DIR = 'output'
IMG_SIZE = 256
BATCH_SIZE = 32
EPOCHS = 100

def setup_directories():
    """Create output directories"""
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print("✓ Directories created")

def setup_gpu():
    """Configure GPU"""
    gpus = tf.config.list_physical_devices('GPU')
    if gpus:
        for gpu in gpus:
            tf.config.experimental.set_memory_growth(gpu, True)
        print(f"✓ GPU ready: {len(gpus)} device(s)")
    else:
        print("⚠ No GPU - using CPU (slower)")

def build_model(num_classes):
    """Build DenseNet121 transfer learning model - EXACT SAME AS NOTEBOOK"""
    print(f"\n📊 Building DenseNet121 model for {num_classes} classes...")
    
    # Load pre-trained DenseNet121 (exactly like notebook)
    conv_base = DenseNet121(
        weights='imagenet',
        include_top=False,
        input_shape=(IMG_SIZE, IMG_SIZE, 3),
        pooling='avg'
    )
    
    # Freeze base model (exactly like notebook)
    conv_base.trainable = False
    print("✓ Froze DenseNet121 weights (transfer learning)")
    
    # Build model with custom head (exactly like notebook)
    model = models.Sequential()
    model.add(conv_base)
    model.add(layers.BatchNormalization())
    model.add(layers.Dense(256, activation='relu'))
    model.add(layers.Dropout(0.35))
    model.add(layers.BatchNormalization())
    model.add(layers.Dense(120, activation='relu'))
    model.add(layers.Dense(num_classes, activation='softmax'))
    
    # Compile (exactly like notebook)
    model.compile(
        optimizer=optimizers.Adam(learning_rate=0.0001),
        loss='categorical_crossentropy',
        metrics=['accuracy']
    )
    
    print("✓ Model built and compiled")
    return model

def load_data(data_dir):
    """Load training and validation data using image_dataset_from_directory"""
    print(f"\n📂 Loading data from: {data_dir}")
    
    # Check if directories exist
    train_path = os.path.join(data_dir, 'train')
    val_path = os.path.join(data_dir, 'val')
    
    if not os.path.exists(train_path):
        print(f"❌ Error: {train_path} not found!")
        return None, None, None
    
    if not os.path.exists(val_path):
        print(f"❌ Error: {val_path} not found!")
        return None, None, None
    
    print("✓ Train and Val folders found")
    
    # Load training data using image_dataset_from_directory (like the notebook)
    train_data = tf.keras.utils.image_dataset_from_directory(
        train_path,
        labels='inferred',
        label_mode='categorical',
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE
    )
    
    # Get class names (before mapping)
    class_names = train_data.class_names
    num_classes = len(class_names)
    
    # Apply normalization (x / 255.0)
    train_data = train_data.map(lambda x, y: (x / 255.0, y))
    
    # Load validation data
    val_data = tf.keras.utils.image_dataset_from_directory(
        val_path,
        labels='inferred',
        label_mode='categorical',
        image_size=(IMG_SIZE, IMG_SIZE),
        batch_size=BATCH_SIZE
    )
    val_data = val_data.map(lambda x, y: (x / 255.0, y))
    
    print(f"✓ Classes ({num_classes}): {', '.join(class_names)}")
    
    return train_data, val_data, class_names

def train(model, train_data, val_data):
    """Train the model (exactly like notebook)"""
    print(f"\n🚀 Training for {EPOCHS} epochs...")
    print("   (Using EarlyStopping - stops if no improvement)")
    
    callback_list = [
        callbacks.EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True,
            verbose=1
        )
    ]
    
    history = model.fit(
        train_data,
        epochs=EPOCHS,
        validation_data=val_data,
        callbacks=callback_list,
        verbose=1
    )
    
    print("\n✓ Training complete!")
    return history

def evaluate(model, val_data, class_names):
    """Evaluate model on validation data"""
    print("\n📊 Evaluating model on validation data...")
    
    val_loss, val_accuracy = model.evaluate(val_data, verbose=1)
    
    print(f"\n{'='*50}")
    print(f"🌱 TOMATO DISEASE DETECTION - RESULTS")
    print(f"{'='*50}")
    print(f"Validation Accuracy: {val_accuracy*100:.2f}%")
    print(f"Validation Loss: {val_loss:.4f}")
    print(f"{'='*50}\n")
    
    return val_accuracy

def save_model(model, class_names):
    """Save model as .h5 and convert to .tflite"""
    print("\n💾 Saving model...")
    
    # Save as Keras H5
    h5_path = os.path.join(OUTPUT_DIR, 'tomato_model.h5')
    model.save(h5_path)
    print(f"✓ Keras model saved: {h5_path}")
    
    # Save class names
    classes_dict = {str(i): name for i, name in enumerate(class_names)}
    classes_path = os.path.join(OUTPUT_DIR, 'classes.json')
    with open(classes_path, 'w') as f:
        json.dump(classes_dict, f, indent=4)
    print(f"✓ Classes saved: {classes_path}")
    
    # Convert to TFLite
    print("\n📦 Converting to TensorFlow Lite...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS,
        tf.lite.OpsSet.SELECT_TF_OPS
    ]
    
    tflite_model = converter.convert()
    tflite_path = os.path.join(OUTPUT_DIR, 'tomato_model.tflite')
    
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    
    size_mb = os.path.getsize(tflite_path) / (1024 * 1024)
    print(f"✓ TFLite model saved: {tflite_path} ({size_mb:.1f} MB)")
    
    print(f"\n✅ Both models saved successfully!")

def convert_to_tflite(model):
    """Deprecated - TFLite conversion now handled by save_model()"""
    pass

def plot_history(history):
    """Plot training history"""
    print("\n📈 Plotting training history...")
    
    fig, axes = plt.subplots(1, 2, figsize=(15, 5))
    
    # Accuracy
    axes[0].plot(history.history['accuracy'], label='Train Accuracy')
    axes[0].plot(history.history['val_accuracy'], label='Val Accuracy')
    axes[0].set_xlabel('Epoch')
    axes[0].set_ylabel('Accuracy')
    axes[0].set_title('Model Accuracy')
    axes[0].legend()
    axes[0].grid(True)
    
    # Loss
    axes[1].plot(history.history['loss'], label='Train Loss')
    axes[1].plot(history.history['val_loss'], label='Val Loss')
    axes[1].set_xlabel('Epoch')
    axes[1].set_ylabel('Loss')
    axes[1].set_title('Model Loss')
    axes[1].legend()
    axes[1].grid(True)
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'training_history.png'), dpi=300)
    print(f"✓ Plot saved: training_history.png")
    plt.close()

def main():
    """Main training pipeline"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Tomato Disease Detection - Train DenseNet121 model',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python train.py                              # Uses default path
  python train.py /path/to/tomato/data         # Custom path with train/ and val/ folders
        """
    )
    parser.add_argument(
        'data_path',
        nargs='?',
        default=DEFAULT_DATA_DIR,
        help=f'Path to dataset (should contain train/ and val/ folders). Default: {DEFAULT_DATA_DIR}'
    )
    
    args = parser.parse_args()
    data_path = args.data_path
    
    print("="*60)
    print("🌱 Tomato Disease Detection - Simple Trainer")
    print("="*60)
    print(f"📂 Dataset path: {data_path}")
    print(f"📦 Output path: {OUTPUT_DIR}/")
    print("="*60)
    
    # Setup
    setup_directories()
    setup_gpu()
    
    # Load data
    train_data, val_data, class_names = load_data(data_path)
    num_classes = len(class_names)
    print(f"✓ Classes: {class_names}")
    
    # Build model
    print("\n🏗️ Building DenseNet121 model...")
    model = build_model(num_classes)
    print(f"✓ Model ready with {num_classes} output classes")
    
    # Train
    print("\n🚀 Starting training...")
    history = train(model, train_data, val_data)
    
    # Evaluate
    print("\n📊 Evaluating on validation set...")
    val_accuracy = evaluate(model, val_data, class_names)
    
    # Save
    save_model(model, class_names)
    plot_history(history)
    
    print(f"\n{'='*60}")
    print(f"✅ Training Complete!")
    print(f"📈 Validation Accuracy: {val_accuracy*100:.2f}%")
    print(f"💾 Models saved to: {OUTPUT_DIR}/")
    print(f"   - tomato_model.h5 (Keras format)")
    print(f"   - tomato_model.tflite (Mobile format)")
    print(f"   - classes.json (Class names)")
    print(f"   - training_history.png (Plots)")
    print(f"{'='*60}")

if __name__ == '__main__':
    main()
