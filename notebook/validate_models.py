#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Tea Leaf Disease Detection - Model Validation & Testing
Evaluates trained models and generates detailed reports

Usage:
    python validate_models.py --model-path models/tea_disease_efficientnet_best.h5 --test-dir test
"""

import os
import json
import argparse
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from sklearn.metrics import (
    classification_report, confusion_matrix, accuracy_score,
    precision_score, recall_score, f1_score, roc_auc_score
)
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime

class ModelValidator:
    """Validate and test trained models"""
    
    CLASSES = [
        'Algal Spot',
        'Brown Blight',
        'Gray Blight',
        'Healthy',
        'Helopeltis',
        'Red Spot'
    ]
    
    def __init__(self, model_path):
        self.model_path = model_path
        self.model = None
        self.load_model()
    
    def load_model(self):
        """Load trained model"""
        print(f"Loading model: {self.model_path}")
        self.model = tf.keras.models.load_model(self.model_path)
        print("✓ Model loaded successfully")
        print(f"  Input shape: {self.model.input_shape}")
        print(f"  Output shape: {self.model.output_shape}")
        print(f"  Parameters: {self.model.count_params():,}")
    
    def evaluate_on_directory(self, test_dir, batch_size=32):
        """Evaluate model on test directory"""
        print(f"\nEvaluating on test directory: {test_dir}")
        
        test_datagen = ImageDataGenerator(rescale=1./255)
        
        test_generator = test_datagen.flow_from_directory(
            test_dir,
            target_size=(224, 224),
            batch_size=batch_size,
            class_mode='categorical',
            shuffle=False
        )
        
        # Get predictions
        print("Generating predictions...")
        predictions = self.model.predict(test_generator, verbose=1)
        
        # Get true labels
        true_labels = test_generator.classes
        predicted_labels = np.argmax(predictions, axis=1)
        
        return {
            'true_labels': true_labels,
            'predicted_labels': predicted_labels,
            'predictions': predictions,
            'class_indices': test_generator.class_indices
        }
    
    def calculate_metrics(self, results):
        """Calculate detailed metrics"""
        true = results['true_labels']
        pred = results['predicted_labels']
        predictions_proba = results['predictions']
        
        # Overall metrics
        accuracy = accuracy_score(true, pred)
        precision = precision_score(true, pred, average='weighted', zero_division=0)
        recall = recall_score(true, pred, average='weighted', zero_division=0)
        f1 = f1_score(true, pred, average='weighted', zero_division=0)
        
        # Per-class metrics
        class_report = classification_report(
            true, pred,
            target_names=self.CLASSES,
            output_dict=True,
            zero_division=0
        )
        
        # Confusion matrix
        cm = confusion_matrix(true, pred)
        
        return {
            'accuracy': accuracy,
            'precision': precision,
            'recall': recall,
            'f1': f1,
            'class_report': class_report,
            'confusion_matrix': cm
        }
    
    def print_metrics(self, metrics):
        """Print metrics in human-readable format"""
        print("\n" + "="*70)
        print("MODEL EVALUATION RESULTS")
        print("="*70)
        
        print("\n📊 OVERALL METRICS:")
        print(f"  Accuracy:  {metrics['accuracy']*100:.2f}%")
        print(f"  Precision: {metrics['precision']*100:.2f}%")
        print(f"  Recall:    {metrics['recall']*100:.2f}%")
        print(f"  F1-Score:  {metrics['f1']*100:.2f}%")
        
        print("\n📋 PER-CLASS METRICS:")
        print("-" * 70)
        print(f"{'Disease':<20} {'Precision':<15} {'Recall':<15} {'F1-Score':<15}")
        print("-" * 70)
        
        for class_name in self.CLASSES:
            if class_name in metrics['class_report']:
                data = metrics['class_report'][class_name]
                print(f"{class_name:<20} "
                      f"{data['precision']*100:>6.2f}% "
                      f"{' '*7} "
                      f"{data['recall']*100:>6.2f}% "
                      f"{' '*7} "
                      f"{data['f1-score']*100:>6.2f}%")
        
        print("-" * 70)
        
        print("\n✓ Summary:")
        print(f"  Total test samples: {len(metrics['confusion_matrix'])}")
        print(f"  Number of classes: {len(self.CLASSES)}")
    
    def plot_confusion_matrix(self, metrics, output_path='confusion_matrix.png'):
        """Plot confusion matrix"""
        cm = metrics['confusion_matrix']
        
        plt.figure(figsize=(10, 8))
        sns.heatmap(
            cm,
            annot=True,
            fmt='d',
            cmap='Blues',
            xticklabels=self.CLASSES,
            yticklabels=self.CLASSES,
            cbar_kws={'label': 'Count'}
        )
        plt.title('Confusion Matrix - Tea Leaf Disease Detection')
        plt.ylabel('True Label')
        plt.xlabel('Predicted Label')
        plt.xticks(rotation=45, ha='right')
        plt.yticks(rotation=0)
        plt.tight_layout()
        plt.savefig(output_path, dpi=150)
        print(f"\n✓ Confusion matrix saved: {output_path}")
        plt.close()
    
    def plot_class_metrics(self, metrics, output_path='class_metrics.png'):
        """Plot per-class metrics"""
        classes = self.CLASSES
        precisions = []
        recalls = []
        f1_scores = []
        
        for cls in classes:
            if cls in metrics['class_report']:
                data = metrics['class_report'][cls]
                precisions.append(data['precision'])
                recalls.append(data['recall'])
                f1_scores.append(data['f1-score'])
        
        x = np.arange(len(classes))
        width = 0.25
        
        fig, ax = plt.subplots(figsize=(12, 6))
        ax.bar(x - width, precisions, width, label='Precision', alpha=0.8)
        ax.bar(x, recalls, width, label='Recall', alpha=0.8)
        ax.bar(x + width, f1_scores, width, label='F1-Score', alpha=0.8)
        
        ax.set_xlabel('Disease Class')
        ax.set_ylabel('Score')
        ax.set_title('Per-Class Metrics - Tea Leaf Disease Detection')
        ax.set_xticks(x)
        ax.set_xticklabels(classes, rotation=45, ha='right')
        ax.legend()
        ax.set_ylim([0, 1.1])
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(output_path, dpi=150)
        print(f"✓ Class metrics saved: {output_path}")
        plt.close()
    
    def generate_report(self, metrics, output_path='validation_report.json'):
        """Generate detailed report"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'model_path': self.model_path,
            'overall_metrics': {
                'accuracy': float(metrics['accuracy']),
                'precision': float(metrics['precision']),
                'recall': float(metrics['recall']),
                'f1_score': float(metrics['f1'])
            },
            'per_class_metrics': {}
        }
        
        for cls in self.CLASSES:
            if cls in metrics['class_report']:
                data = metrics['class_report'][cls]
                report['per_class_metrics'][cls] = {
                    'precision': float(data['precision']),
                    'recall': float(data['recall']),
                    'f1_score': float(data['f1-score']),
                    'support': int(data['support'])
                }
        
        with open(output_path, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"✓ Report saved: {output_path}")
        return report


class ModelComparison:
    """Compare multiple models"""
    
    def __init__(self, model_paths):
        self.model_paths = model_paths
        self.validators = {}
        self.results = {}
    
    def evaluate_all(self, test_dir):
        """Evaluate all models"""
        print("\n" + "="*70)
        print("COMPARING MULTIPLE MODELS")
        print("="*70)
        
        for name, path in self.model_paths.items():
            print(f"\n[{name}]")
            validator = ModelValidator(path)
            results = validator.evaluate_on_directory(test_dir)
            metrics = validator.calculate_metrics(results)
            
            self.validators[name] = validator
            self.results[name] = (results, metrics)
            
            validator.print_metrics(metrics)
    
    def compare_accuracies(self):
        """Compare model accuracies"""
        print("\n" + "="*70)
        print("MODEL COMPARISON")
        print("="*70)
        print(f"\n{'Model':<30} {'Accuracy':<15} {'F1-Score':<15}")
        print("-" * 70)
        
        accuracies = {}
        for name, (_, metrics) in self.results.items():
            accuracies[name] = metrics['accuracy']
            print(f"{name:<30} "
                  f"{metrics['accuracy']*100:>6.2f}% "
                  f"{' '*6} "
                  f"{metrics['f1']*100:>6.2f}%")
        
        best_model = max(accuracies, key=accuracies.get)
        print("-" * 70)
        print(f"\n🏆 Best Model: {best_model} ({accuracies[best_model]*100:.2f}%)")


def main():
    parser = argparse.ArgumentParser(
        description='Validate and test Tea Leaf Disease models'
    )
    parser.add_argument('--model-path', type=str, required=True,
                       help='Path to trained model')
    parser.add_argument('--test-dir', type=str, required=True,
                       help='Path to test directory')
    parser.add_argument('--output-dir', type=str, default='validation_results',
                       help='Output directory for results')
    parser.add_argument('--compare-models', action='store_true',
                       help='Compare multiple models')
    parser.add_argument('--model-paths', type=json.loads, default={},
                       help='Multiple model paths (JSON format)')
    
    args = parser.parse_args()
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    if args.compare_models and args.model_paths:
        # Compare multiple models
        comparator = ModelComparison(args.model_paths)
        comparator.evaluate_all(args.test_dir)
    else:
        # Single model evaluation
        print("="*70)
        print("🌾 TEA LEAF DISEASE DETECTION - MODEL VALIDATION")
        print("="*70)
        
        validator = ModelValidator(args.model_path)
        
        # Evaluate
        print(f"\n[1/4] Evaluating model on test set...")
        results = validator.evaluate_on_directory(args.test_dir)
        
        # Calculate metrics
        print(f"\n[2/4] Calculating metrics...")
        metrics = validator.calculate_metrics(results)
        
        # Print results
        print(f"\n[3/4] Results:")
        validator.print_metrics(metrics)
        
        # Generate visualizations
        print(f"\n[4/4] Generating visualizations...")
        validator.plot_confusion_matrix(
            metrics,
            os.path.join(args.output_dir, 'confusion_matrix.png')
        )
        validator.plot_class_metrics(
            metrics,
            os.path.join(args.output_dir, 'class_metrics.png')
        )
        
        # Generate report
        report = validator.generate_report(
            metrics,
            os.path.join(args.output_dir, 'validation_report.json')
        )
        
        print("\n" + "="*70)
        print("✅ VALIDATION COMPLETE")
        print("="*70)
        print(f"\nOutput files in: {args.output_dir}/")
        print(f"  - confusion_matrix.png")
        print(f"  - class_metrics.png")
        print(f"  - validation_report.json")


if __name__ == '__main__':
    main()
