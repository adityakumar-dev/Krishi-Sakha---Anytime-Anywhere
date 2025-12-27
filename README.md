# 🌾 Krishi Sakha - Anytime, Anywhere

**AI-Powered Agricultural Assistant for Farmers**

Krishi Sakha is a comprehensive mobile application that leverages AI, and computer vision to empower farmers with real-time agricultural insights, disease detection, and personalized recommendations.

---

## 📱 Project Architecture

```
Krishi-Sakha/
├── krishi_sakha/          # Flutter Mobile Application (Android/iOS)
├── krishi_sakha_py/       # FastAPI Backend Server
└── notebook/              # Research & ML Model Training
```

### 🎯 Core Components

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Mobile App** | Flutter + Dart | Cross-platform agricultural assistant with offline support |
| **Backend** | FastAPI + Python | AI inference, RAG system, weather data, IoT integration |
| **Research** | TensorFlow + Keras | Disease detection models, ML experimentation |

---

## 🚀 Key Features

### 📲 Mobile Application (`krishi_sakha/`)
- **Multi-modal AI Chat**: Voice & text interaction in local languages
- **Disease Detection**: Real-time plant disease identification using camera
- **Weather Integration**: Live weather data with IoT sensor support
- **Offline Mode**: LLaMA-based on-device inference
- **Crop Advisory**: Personalized recommendations based on location
- **Market Prices**: Real-time agricultural commodity prices

### ⚙️ Backend Server (`krishi_sakha_py/`)
- **RAG System**: Context-aware responses using ChromaDB vector database
- **LLM Integration**: Ollama + Gemini API for intelligent responses
- **IoT Gateway**: Serial communication with weather stations
- **Translation**: Multi-language support (English, Malayalam Hindi, Assamese, Bengali)
- **Document Processing**: PDF parsing for agricultural knowledge base

### 🔬 Research & Models (`notebook/`)
- **Tea Leaf Disease Detection**: CNN-based model with 95%+ accuracy
- **Tomato Disease Detection**: DenseNet implementation (96% accuracy)
- **Model Optimization**: TFLite conversion for mobile deployment
- **Dataset Management**: Training pipelines with validation

---

## 📦 Installation & Setup

### Prerequisites
- **Flutter SDK** (3.24+)
- **Python** (3.11+)
- **CUDA** (optional, for GPU training)

### 1. Mobile Application Setup

```bash
cd krishi_sakha
flutter pub get
flutter run
```

**Dependencies**: `pubspec.yaml`
- `langchain_ollama` - On-device LLM
- `flutter_tts`, `speech_to_text` - Voice interaction
- `tflite_flutter` - ML model inference
- `geolocator`, `weather` - Location & weather
- `firebase_messaging` - Push notifications

### 2. Backend Server Setup

```bash
cd krishi_sakha_py
uv sync  # or pip install -r requirements.txt
uvicorn main:app --reload
```

**Dependencies**: `pyproject.toml`
- `fastapi`, `uvicorn` - Web framework
- `langchain`, `chromadb` - RAG system
- `tensorflow`, `opencv-python` - ML inference
- `sentence-transformers` - Embeddings
- `google-generativeai` - Gemini API

### 3. ML Model Training

```bash
cd notebook/models/archive\ \(1\)/Tea_Leaf_Disease
python prepare_data.py  # Split dataset
python train_model.py   # Train model
```

**Dependencies**:
- `tensorflow` (GPU-enabled)
- `scikit-learn`, `matplotlib`, `seaborn`
- `opencv-python` - Image preprocessing

---

## 🏆 Hackathon Highlights

### Problem Statement
Farmers lack accessible, real-time agricultural expertise leading to crop losses, inefficient resource use, and reduced income.

### Our Solution
An AI-powered mobile assistant that provides:
- ✅ Instant disease detection via smartphone camera
- ✅ Voice-based queries in local languages
- ✅ Real-time weather monitoring with IoT sensors
- ✅ Offline functionality for remote areas
- ✅ Personalized crop recommendations

### Technical Innovations
1. **Hybrid AI Architecture**: On-device LLaMA + Cloud Gemini for optimal performance
2. **Multi-modal Input**: Voice, text, and image-based interactions
3. **Edge Computing**: TFLite models for real-time disease detection
4. **RAG System**: Context-aware responses using agricultural knowledge base


### Impact Metrics
- 🎯 95%+ disease detection accuracy
- ⚡ <100ms inference time on mobile
- 🌐 Support for 4+ languages
- 📡 Offline mode with on-device LLM
- 🔋 Battery-optimized mobile deployment

---

## 🧪 ML Models

### Tea Leaf Disease Detection
- **Architecture**: Custom CNN (Conv32→64→128→256)
- **Input Size**: 128×128×3
- **Classes**: 6 diseases (algal spot, brown blight, gray blight, healthy, helopeltis, red spot)
- **Accuracy**: 95%+ validation accuracy
- **Model Size**: ~3.5MB (TFLite quantized)

### Training Configuration
```python
IMAGE_SIZE = 128
BATCH_SIZE = 32
EPOCHS = 100 (with early stopping)
OPTIMIZER = Adam (lr=0.001)
```

---

## 🗂️ Project Structure

```
Krishi-Sakha/
├── krishi_sakha/                    # Flutter Mobile App
│   ├── lib/
│   │   ├── brain/                   # On-device LLM
│   │   ├── modules/                 # Feature modules
│   │   ├── routes/                  # API integration
│   │   └── services/                # Core services
│   ├── assets/                      # Images, models, localization
│   └── pubspec.yaml
│
├── krishi_sakha_py/                 # Backend Server
│   ├── brain/                       # LLM & RAG
│   ├── modules/                     # Business logic
│   ├── routes/                      # API endpoints
│   ├── configs/                     # Configuration
│   ├── main.py                      # FastAPI app
│   └── pyproject.toml
│
└── notebook/                        # Research
    ├── models/
    │   └── Tea_Leaf_Disease/
    │       ├── train_model.py       # Training script
    │       ├── validate_model.py    # Evaluation
    │       └── prepare_data.py      # Data preprocessing
    └── data/                        # Datasets

```

---

## 🎓 Team & Credits

Built with ❤️ for farmers by agricultural AI enthusiasts.

### Technologies Used
- **Mobile**: Flutter, Dart, TFLite
- **Backend**: Python, FastAPI, LangChain, ChromaDB
- **ML**: TensorFlow, Keras, OpenCV, scikit-learn
- **Cloud**: Firebase, Google Gemini API

---

## 📄 License

MIT License - Free for educational and agricultural use.

---

## 🤝 Contributing

We welcome contributions! Please check issues or create PRs for:
- New language support
- Additional disease models
- UI/UX improvements

---

**Built for SIH 2025** 🏆
