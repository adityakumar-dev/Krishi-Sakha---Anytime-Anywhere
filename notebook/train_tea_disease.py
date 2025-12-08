#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tea Leaf Disease Detection - Quick Training Script
Optimized for immediate execution with your existing dataset

Usage:
    python train_tea_disease.py --model efficientnet --epochs 50 --batch-size 32
    
Options:
    --model: 'efficientnet' (recommended), 'custom', or 'resnet50'
    --epochs: number of training epochs
    --batch-size: batch size for training
    --gpu: use GPU if available (default: True)
"""

import os
import sys
import json
import argparse
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers, callbacks
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import EfficientNetB3, ResNet50, VGG16
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import cv2
from datetime import datetime

# ============================================================================
# CONFIGURATION
# ============================================================================

class Config:
    """Training configuration"""
    IMAGE_SIZE = 224
    BATCH_SIZE = 32
    EPOCHS = 50
    LEARNING_RATE = 1e-3
    VALIDATION_SPLIT = 0.2
    
    # Disease classes
    CLASSES = [
        'Algal Spot',
        'Brown Blight', 
        'Gray Blight',
        'Healthy',
        'Helopeltis',
        'Red Spot'
    ]
    
    NUM_CLASSES = len(CLASSES)
    
    # Paths
    OUTPUT_DIR = 'models'
    RESULTS_DIR = 'results'
    TIMESTAMP = datetime.now().strftime('%Y%m%d_%H%M%S')

# ============================================================================
# IMAGE PREPROCESSING
# ============================================================================

class ImagePreprocessor:
    """Advanced image preprocessing"""
    
    def __init__(self, target_size=224):
        self.target_size = target_size
    
    @staticmethod
    def extract_leaf_roi(image_path):
        """Extract leaf region using color-based segmentation"""
        img = cv2.imread(image_path)
        if img is None:
            return None
        
        # Convert to HSV
        hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
        
        # Green color range for healthy leaves
        lower = np.array([35, 50, 50])
        upper = np.array([85, 255, 255])
        mask = cv2.inRange(hsv, lower, upper)
        
        # Morphological operations
        kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
        mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)
        
        # Find contours
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if len(contours) == 0:
            return cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Get largest contour
        largest = max(contours, key=cv2.contourArea)
        x, y, w, h = cv2.boundingRect(largest)
        
        # Add padding
        padding = 10
        x = max(0, x - padding)
        y = max(0, y - padding)
        w = min(img.shape[1] - x, w + 2*padding)
        h = min(img.shape[0] - y, h + 2*padding)
        
        roi = img[y:y+h, x:x+w]
        return cv2.cvtColor(roi, cv2.COLOR_BGR2RGB)
    
    def preprocess_batch_from_directory(self, root_dir):
        """Load and preprocess all images from directory structure"""
        images = []
        labels = []
        label_names = []
        
        for label_idx, class_name in enumerate(sorted(os.listdir(root_dir))):
            class_dir = os.path.join(root_dir, class_name)
            if not os.path.isdir(class_dir):
                continue
            
            label_names.append(class_name)
            print(f"Processing {class_name}...", end=' ')
            count = 0
            
            for img_file in os.listdir(class_dir):
                if not img_file.lower().endswith(('.jpg', '.jpeg', '.png', '.bmp')):
                    continue
                
                img_path = os.path.join(class_dir, img_file)
                try:
                    # Extract ROI
                    roi = self.extract_leaf_roi(img_path)
                    if roi is None:
                        continue
                    
                    # Resize
                    roi = cv2.resize(roi, (self.target_size, self.target_size))
                    
                    # Normalize
                    roi = roi.astype('float32') / 255.0
                    
                    images.append(roi)
                    labels.append(label_idx)
                    count += 1
                except Exception as e:
                    print(f"Error processing {img_file}: {e}")
                    continue
            
            print(f"({count} images)")
        
        print(f"\nTotal images loaded: {len(images)}")
        return np.array(images), np.array(labels), label_names

# ============================================================================
# MODEL ARCHITECTURES
# ============================================================================

class ModelBuilder:
    """Build different model architectures"""
    
    @staticmethod
    def efficientnet_b3(input_shape=(224, 224, 3), num_classes=6):
        """EfficientNetB3 with transfer learning"""
        base_model = EfficientNetB3(
            input_shape=input_shape,
            weights='imagenet',
            include_top=False
        )
        
        # Freeze base model initially
        base_model.trainable = False
        
        model = models.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(512, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            layers.Dense(num_classes, activation='softmax')
        ])
        
        return model, base_model
    
    @staticmethod
    def resnet50(input_shape=(224, 224, 3), num_classes=6):
        """ResNet50 with transfer learning"""
        base_model = ResNet50(
            input_shape=input_shape,
            weights='imagenet',
            include_top=False
        )
        
        base_model.trainable = False
        
        model = models.Sequential([
            base_model,
            layers.GlobalAveragePooling2D(),
            layers.Dense(512, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.3),
            layers.Dense(num_classes, activation='softmax')
        ])
        
        return model, base_model
    
    @staticmethod
    def custom_cnn(input_shape=(224, 224, 3), num_classes=6):
        """Custom optimized CNN"""
        model = models.Sequential([
            # Block 1
            layers.Conv2D(64, (3, 3), padding='same', input_shape=input_shape),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.Conv2D(64, (3, 3), padding='same'),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Block 2
            layers.Conv2D(128, (3, 3), padding='same'),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.Conv2D(128, (3, 3), padding='same'),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Block 3
            layers.Conv2D(256, (3, 3), padding='same'),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.Conv2D(256, (3, 3), padding='same'),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Block 4
            layers.Conv2D(512, (3, 3), padding='same'),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.Conv2D(512, (3, 3), padding='same'),
            layers.BatchNormalization(),
            layers.Activation('relu'),
            layers.MaxPooling2D((2, 2)),
            layers.Dropout(0.25),
            
            # Dense
            layers.GlobalAveragePooling2D(),
            layers.Dense(512, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(256, activation='relu'),
            layers.BatchNormalization(),
            layers.Dropout(0.5),
            layers.Dense(num_classes, activation='softmax')
        ])
        
        return model, None

# ============================================================================
# TRAINING
# ============================================================================

class Trainer:
    """Training pipeline"""
    
    def __init__(self, model, model_name, base_model=None):
        self.model = model
        self.model_name = model_name
        self.base_model = base_model
        self.history = None
        self.class_indices = None
    
    def compile(self, learning_rate=1e-3):
        """Compile model"""
        self.model.compile(
            optimizer=optimizers.Adam(learning_rate=learning_rate),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        print(f"✓ Model compiled")
        print(f"  Total parameters: {self.model.count_params():,}")
    
    @staticmethod
    def get_data_generators():
        """Get data augmentation generators"""
        train_gen = ImageDataGenerator(
            rescale=1./255,
            rotation_range=40,
            width_shift_range=0.2,
            height_shift_range=0.2,
            shear_range=0.2,
            zoom_range=0.3,
            horizontal_flip=True,
            vertical_flip=True,
            fill_mode='nearest',
            brightness_range=[0.8, 1.2],
            channel_shift_range=20
        )
        
        val_gen = ImageDataGenerator(rescale=1./255)
        
        return train_gen, val_gen
    
    def train(self, train_dir, val_dir, epochs=50, batch_size=32):
        """Train the model"""
        train_gen, val_gen = self.get_data_generators()
        
        # Load training data
        train_data = train_gen.flow_from_directory(
            train_dir,
            target_size=(224, 224),
            batch_size=batch_size,
            class_mode='categorical',
            shuffle=True
        )
        
        # Load validation data
        val_data = val_gen.flow_from_directory(
            val_dir,
            target_size=(224, 224),
            batch_size=batch_size,
            class_mode='categorical'
        )
        
        self.class_indices = train_data.class_indices
        
        # Callbacks
        cbs = [
            callbacks.EarlyStopping(
                monitor='val_loss',
                patience=15,
                restore_best_weights=True,
                verbose=1
            ),
            callbacks.ReduceLROnPlateau(
                monitor='val_loss',
                factor=0.5,
                patience=5,
                min_lr=1e-7,
                verbose=1
            ),
            callbacks.ModelCheckpoint(
                f'{Config.OUTPUT_DIR}/{self.model_name}_best.h5',
                monitor='val_accuracy',
                save_best_only=True,
                verbose=1
            ),
            callbacks.TensorBoard(
                log_dir=f'{Config.RESULTS_DIR}/logs',
                histogram_freq=1
            )
        ]
        
        print(f"\n{'='*60}")
        print(f"Training {self.model_name}...")
        print(f"{'='*60}")
        
        self.history = self.model.fit(
            train_data,
            epochs=epochs,
            validation_data=val_data,
            callbacks=cbs,
            verbose=1
        )
        
        return self.history
    
    def fine_tune(self, train_dir, val_dir, epochs=10, batch_size=32):
        """Fine-tune by unfreezing base model"""
        if self.base_model is None:
            print("No base model to fine-tune")
            return
        
        print("\n" + "="*60)
        print("Fine-tuning base model...")
        print("="*60)
        
        # Unfreeze base model
        self.base_model.trainable = True
        
        # Lower learning rate for fine-tuning
        self.model.compile(
            optimizer=optimizers.Adam(learning_rate=1e-5),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )
        
        train_gen, val_gen = self.get_data_generators()
        
        train_data = train_gen.flow_from_directory(
            train_dir,
            target_size=(224, 224),
            batch_size=batch_size,
            class_mode='categorical',
            shuffle=True
        )
        
        val_data = val_gen.flow_from_directory(
            val_dir,
            target_size=(224, 224),
            batch_size=batch_size,
            class_mode='categorical'
        )
        
        self.history = self.model.fit(
            train_data,
            epochs=epochs,
            validation_data=val_data,
            verbose=1
        )
    
    def evaluate(self, test_dir):
        """Evaluate model"""
        test_gen = ImageDataGenerator(rescale=1./255)
        
        test_data = test_gen.flow_from_directory(
            test_dir,
            target_size=(224, 224),
            batch_size=32,
            class_mode='categorical',
            shuffle=False
        )
        
        loss, accuracy = self.model.evaluate(test_data, verbose=1)
        print(f"\nTest Accuracy: {accuracy*100:.2f}%")
        
        return accuracy
    
    def plot_history(self):
        """Plot training history"""
        if self.history is None:
            print("No training history")
            return
        
        fig, axes = plt.subplots(1, 2, figsize=(14, 5))
        
        axes[0].plot(self.history.history['accuracy'], label='Train')
        axes[0].plot(self.history.history['val_accuracy'], label='Validation')
        axes[0].set_title('Accuracy')
        axes[0].set_xlabel('Epoch')
        axes[0].set_ylabel('Accuracy')
        axes[0].legend()
        axes[0].grid(True)
        
        axes[1].plot(self.history.history['loss'], label='Train')
        axes[1].plot(self.history.history['val_loss'], label='Validation')
        axes[1].set_title('Loss')
        axes[1].set_xlabel('Epoch')
        axes[1].set_ylabel('Loss')
        axes[1].legend()
        axes[1].grid(True)
        
        plt.tight_layout()
        plt.savefig(f'{Config.RESULTS_DIR}/{self.model_name}_history.png', dpi=150)
        print(f"✓ Plot saved: {Config.RESULTS_DIR}/{self.model_name}_history.png")
        plt.close()

# ============================================================================
# CONVERSION TO TFLITE
# ============================================================================

def convert_to_tflite(model, output_path, quantize=True):
    """Convert Keras model to TensorFlow Lite"""
    print(f"\nConverting to TFLite...")
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    if quantize:
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    size_mb = len(tflite_model) / (1024 * 1024)
    print(f"✓ TFLite model saved: {output_path}")
    print(f"  Size: {size_mb:.2f} MB")

# ============================================================================
# MAIN EXECUTION
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description='Train Tea Leaf Disease Model')
    parser.add_argument('--model', type=str, default='efficientnet',
                       choices=['efficientnet', 'resnet50', 'custom'],
                       help='Model architecture to use')
    parser.add_argument('--epochs', type=int, default=50,
                       help='Number of training epochs')
    parser.add_argument('--batch-size', type=int, default=32,
                       help='Batch size for training')
    parser.add_argument('--train-dir', type=str, default='train',
                       help='Path to training directory')
    parser.add_argument('--val-dir', type=str, default='val',
                       help='Path to validation directory')
    parser.add_argument('--test-dir', type=str, default='test',
                       help='Path to test directory')
    parser.add_argument('--fine-tune', action='store_true',
                       help='Fine-tune after initial training')
    
    args = parser.parse_args()
    
    # Create output directories
    os.makedirs(Config.OUTPUT_DIR, exist_ok=True)
    os.makedirs(Config.RESULTS_DIR, exist_ok=True)
    
    print("="*70)
    print("🌾 Tea Leaf Disease Detection - Model Training")
    print("="*70)
    
    # Build model
    print(f"\n[1/6] Building {args.model} model...")
    if args.model == 'efficientnet':
        model, base_model = ModelBuilder.efficientnet_b3()
    elif args.model == 'resnet50':
        model, base_model = ModelBuilder.resnet50()
    else:
        model, base_model = ModelBuilder.custom_cnn()
    
    # Create trainer
    trainer = Trainer(model, f"tea_disease_{args.model}", base_model)
    
    # Compile
    print("\n[2/6] Compiling model...")
    trainer.compile()
    
    # Train
    print(f"\n[3/6] Training model ({args.epochs} epochs)...")
    trainer.train(
        args.train_dir,
        args.val_dir,
        epochs=args.epochs,
        batch_size=args.batch_size
    )
    
    # Fine-tune if requested
    if args.fine_tune and args.model in ['efficientnet', 'resnet50']:
        print("\n[4/6] Fine-tuning...")
        trainer.fine_tune(args.train_dir, args.val_dir, epochs=10)
        step = 5
    else:
        step = 4
    
    # Plot results
    print(f"\n[{step}/6] Plotting results...")
    trainer.plot_history()
    
    # Convert to TFLite
    print(f"\n[{step+1}/6] Converting to TensorFlow Lite...")
    tflite_path = f'{Config.OUTPUT_DIR}/tea_leaf_disease_{args.model}.tflite'
    convert_to_tflite(model, tflite_path, quantize=True)
    
    # Save model info
    model_info = {
        'model_name': f'tea_disease_{args.model}',
        'architecture': args.model,
        'input_size': 224,
        'num_classes': 6,
        'classes': Config.CLASSES,
        'timestamp': Config.TIMESTAMP
    }
    
    with open(f'{Config.OUTPUT_DIR}/model_info.json', 'w') as f:
        json.dump(model_info, f, indent=2)
    
    print("\n" + "="*70)
    print("✅ Training Complete!")
    print("="*70)
    print(f"\n📁 Output files:")
    print(f"  - Model: {Config.OUTPUT_DIR}/tea_disease_{args.model}_best.h5")
    print(f"  - TFLite: {tflite_path}")
    print(f"  - Plot: {Config.RESULTS_DIR}/tea_disease_{args.model}_history.png")
    print(f"\n📱 For Flutter deployment:")
    print(f"  1. Copy {tflite_path}")
    print(f"  2. Paste to: krishi_sakha/assets/model/tea_disease.tflite")
    print(f"  3. Update pubspec.yaml with asset path")
    print(f"  4. Use tea_disease_detector.dart for inference")
    print("="*70)

if __name__ == '__main__':
    main()
