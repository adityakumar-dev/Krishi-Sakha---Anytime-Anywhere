# 🌱 Tomato Disease Detection - Simple Model

Production-ready tomato disease detection with **96% accuracy** using DenseNet121 transfer learning.

**Status:** ✅ Fully Trained & Tested

## 🎯 Model Performance

| Metric | Value |
|--------|-------|
| **Validation Accuracy** | **96.00%** ✅ |
| **Validation Loss** | 0.1344 |
| **Training Epochs** | 37 (with EarlyStopping) |
| **Training Time** | ~30 minutes (RTX 3050) |
| **Diseases Detected** | 10 classes |

## 📁 Quick Start

### Method 1: Using Pre-trained Models (Ready to Use!)
```bash
# Predict with H5 model (best accuracy)
python predict.py /path/to/leaf/image.jpg h5

# Predict with TFLite model (fastest)
python predict.py /path/to/leaf/image.jpg tflite

# Output:
# 🔍 Predicting disease for: image.jpg
# ========================================
# 🌱 TOMATO DISEASE DETECTION
# ========================================
# Disease: Tomato___Early_blight
# Confidence: 99.40%
# ========================================
```

### Method 2: Train on Custom Data
```bash
# 1. Organize your data
python prepare_data.py /your/tomato/images

# 2. Train the model
python train.py /path/to/data

# Creates:
# - output/tomato_model.h5 (32 MB, high precision)
# - output/tomato_model.tflite (7.4 MB, quantized)
# - output/classes.json (disease names)
# - output/training_history.png (accuracy/loss plots)
```

## 📊 Model Specifications

1. **Tomato___Bacterial_spot** - Bacterial leaf spot disease
2. **Tomato___Early_blight** - Early blight fungal disease
3. **Tomato___Late_blight** - Late blight (Phytophthora infestans)
4. **Tomato___Leaf_Mold** - Leaf mold fungal infection
5. **Tomato___Septoria_leaf_spot** - Septoria leaf spot disease
6. **Tomato___Spider_mites** - Two-spotted spider mite damage
7. **Tomato___Target_Spot** - Target spot fungal disease
8. **Tomato___Tomato_Yellow_Leaf_Curl_Virus** - TYLCV virus
9. **Tomato___Tomato_mosaic_virus** - TMV infection
10. **Tomato___healthy** - No disease detected

## 📂 Project Files

```
model/
├── train.py               # Main training script
├── predict.py             # Inference script
├── prepare_data.py        # Data organization utility
├── demo.ipynb             # Interactive demo notebook
├── README.md              # This file
├── .venv/                 # Python virtual environment
│
└── output/                # Generated models & data
    ├── tomato_model.h5    # Full precision model (32 MB)
    ├── tomato_model.tflite # Quantized model (7.4 MB)
    ├── classes.json       # Disease class mapping
    └── training_history.png # Training curves
```

## 🚀 Usage Examples

**Example 1: Predict Early Blight (99.40% confidence)**
```bash
python predict.py /path/to/diseased/leaf.jpg h5
# Output: Disease: Tomato___Early_blight, Confidence: 99.40%
```

**Example 2: Predict Healthy Leaf (100% confidence)**
```bash
python predict.py /path/to/healthy/leaf.jpg tflite
# Output: Disease: Tomato___healthy, Confidence: 100.00%
```

**Example 3: Train on custom dataset**
```bash
python train.py /home/linmar/Desktop/Krishi-Sakha/notebook/models/tomatoleaf/tomato
# Output: New models saved to output/
```

## 💡 Best Practices

- **For Mobile Apps:** Use `tomato_model.tflite` (7.4 MB, fast)
- **For Server/Cloud:** Use `tomato_model.h5` (32 MB, most accurate)
- **Monitor Training:** Check GPU with `nvidia-smi`
- **Test Your Data:** Run predictions on validation set first

## 🔧 Configuration Options

Edit `train.py` to customize:
```python
DEFAULT_DATA_DIR = './tomatoleaf/tomato'  # Change dataset path
OUTPUT_DIR = 'output'                      # Change output folder
IMG_SIZE = 256                              # Input image size
BATCH_SIZE = 32                             # Training batch size
EPOCHS = 100                                # Max epochs
```

---

**Ready for Production** ✅

This model achieves **96% accuracy** and is ready to deploy on:
- 🌐 Web servers (Flask, FastAPI)
- 📱 Mobile apps (TensorFlow Lite)
- 🤖 IoT devices (Raspberry Pi, Jetson)
- ☁️ Cloud platforms (AWS, GCP, Azure)
