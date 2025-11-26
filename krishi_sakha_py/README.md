# Krishi-Sakha: AI-Powered Agricultural Advisory System

An intelligent agricultural advisory system that combines AI-powered crop recommendations with real-time sensor data from HC-05 Bluetooth soil sensors.

## 🌾 Features

- **AI Crop Recommendations**: Uses LangChain + Ollama for intelligent crop advice
- **Real-time Sensor Integration**: HC-05 Bluetooth sensor data for soil moisture and temperature
- **Government Scheme Integration**: State-wise filtering of agricultural schemes from CSV data
- **Streaming Responses**: Real-time streaming of crop advice and sensor data
- **RESTful API**: FastAPI-based microservices architecture

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Main API      │    │  Sensor Service │    │   AI Models     │
│   (FastAPI)     │◄──►│   (FastAPI)     │    │  (Ollama)      │
│                 │    │                 │    │                 │
│ - Chat          │    │ - HC-05 Data    │    │ - Crop Advice   │
│ - Search        │    │ - Streaming     │    │ - General QA    │
│ - Crop Advice   │    │ - Status        │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 ▼
                    ┌─────────────────┐
                    │  CSV Database  │
                    │ (Govt Schemes) │
                    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Python 3.13+
- uv package manager
- Ollama with `gemma3:4b` model
- HC-05 Bluetooth module (optional for sensor features)

### Installation

1. **Clone and setup environment:**
```bash
cd krishi_sakha_py
source .venv/bin/activate  # or create virtual environment
uv sync
```

2. **Start Ollama service:**
```bash
ollama serve
ollama pull gemma3:4b
```

3. **Start the system:**
```bash
python start_system.py
```

This will start both services:
- Main API: http://localhost:8000
- Sensor Service: http://localhost:5001

### Alternative Manual Start

```bash
# Terminal 1: Sensor Service
python sensor_service.py

# Terminal 2: Main API
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
python test_system.py
```

Expected output:
```
🚀 Starting Krishi-Sakha System Tests
==================================================
✅ Main application root endpoint working
✅ Sensor service root endpoint working
✅ Sensor status endpoint working: connection_error: [Errno 2]...
✅ Crop advice endpoint working
🎉 All tests passed! System is ready.
```

## 📡 API Endpoints

### Main API (Port 8000)

#### Crop Advice
```http
POST /crop_advice
Content-Type: application/json

{
  "weather": "Sunny weather with temperature around 25-30°C",
  "soil": "Clay loam soil with pH 6.5-7.0",
  "state": "uttarakhand"
}
```

**Features:**
- Real-time sensor data integration (moisture, temperature)
- Historical crop data analysis (103 crops for Dehradun region)
- Government scheme recommendations
- Data-driven profitability analysis
- Risk assessment and mitigation strategies

**Response:** Server-sent events stream with comprehensive crop recommendations

#### Other Endpoints
- `GET /` - API status
- `POST /chat` - General agricultural chat
- `POST /search` - Internet search for farming info
- `POST /voice` - Voice-based queries

### Sensor Service (Port 5001)

#### Sensor Data
```http
GET /data          # Latest sensor readings
GET /status        # Connection status
GET /stream        # Real-time sensor data stream
POST /reconnect    # Reconnect to HC-05 sensor
```

## 🔧 HC-05 Sensor Setup

### Hardware Requirements
- HC-05 Bluetooth module
- Soil moisture sensor
- Temperature sensor
- Arduino/Raspberry Pi for data transmission

### Connection Setup

1. **Pair HC-05 with your system:**
```bash
# Linux Bluetooth pairing
bluetoothctl
scan on
pair <HC05_MAC_ADDRESS>
trust <HC05_MAC_ADDRESS>
```

2. **Create serial port:**
```bash
sudo rfcomm bind /dev/rfcomm0 <HC05_MAC_ADDRESS>
```

3. **Data Format:**
The sensor should send data in format:
```
MOISTURE:45.2,TEMP:28.5
```

## 📊 Data Sources

### Government Schemes
- CSV file: `temp/ALL_Schemes_Agriculture_Rural_Environment.csv`
- Contains state-wise agricultural schemes and subsidies
- Automatically filtered by state parameter

### Dehradun Crop Historical Data
- CSV file: `temp/dehradun_crop.csv`
- Contains 103 crops with comprehensive historical data:
  - Yield statistics (per acre)
  - Cost of cultivation
  - Selling prices and profit margins
  - Market demand analysis
  - Weather/soil suitability
  - Risk factors and recommendations
- Used by AI for data-driven crop recommendations

### AI Models
- **Crop Advice**: Specialized prompts for agricultural recommendations using historical data
- **General Chat**: Fallback for general farming questions
- **Search**: Internet search preprocessing

## 🔍 Configuration

### Model Configuration (`configs/model_config.py`)
```python
MODEL_NAME = "gemma3:4b"
DEFAULT_SYSTEM_MESSAGE = "..."
CROP_ADVISE_SYSTEM_MESSAGE = "..."
```

### External Services (`configs/external_keys.py`)
- Supabase configuration
- API keys for external services

## 🐛 Troubleshooting

### Common Issues

1. **Sensor Connection Failed**
   - Check HC-05 Bluetooth pairing
   - Verify `/dev/rfcomm0` exists
   - Check sensor data format

2. **Ollama Model Not Found**
   ```bash
   ollama pull gemma3:4b
   ```

3. **Port Already in Use**
   ```bash
   lsof -i :8000  # Check what's using port 8000
   lsof -i :5001  # Check what's using port 5001
   ```

4. **Import Errors**
   ```bash
   uv sync  # Reinstall dependencies
   ```

### Logs and Debugging

- Sensor service logs appear in terminal
- Main API logs via uvicorn
- Use `/docs` endpoint for interactive API testing

## 📈 Future Enhancements

- [ ] Mobile app integration
- [ ] Multiple sensor support
- [ ] Weather API integration
- [ ] Historical data analytics
- [ ] Multi-language support
- [ ] Offline mode

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ for Indian farmers**