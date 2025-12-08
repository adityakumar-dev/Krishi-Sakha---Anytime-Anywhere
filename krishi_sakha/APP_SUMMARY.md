# Krishi Sakha - Smart Farming Assistant App

## Overview
Krishi Sakha is a comprehensive AI-powered mobile application designed to empower farmers with modern agricultural technology. Built with Flutter, it provides real-time weather updates, disease detection, community networking, government scheme information, and multilingual support in English, Hindi, and Malayalam.

---

## 🌟 Key Features

### 1. **Multi-Language Support**
- **Languages**: English, Hindi (हिंदी), Malayalam (മലയാളം)
- **Dynamic Localization**: 190+ translation keys covering entire UI
- **User Preference**: Language persists across sessions based on user profile
- **Seamless Switching**: Change language anytime from settings

### 2. **Weather Services**
#### OpenWeather Integration
- Real-time weather forecasts with 7-day predictions
- Current temperature, humidity, wind speed, pressure
- Sunrise/sunset times
- Multiple city management
- Location-based automatic weather
- Hourly and daily forecasts

#### IMD (India Meteorological Department) Weather
- Official government weather data
- State-wise weather station selection
- Temperature, rainfall, wind, cloud cover metrics
- Station management for preferred locations
- Historical weather data access

### 3. **AI-Powered Plant Disease Detection**
- **TensorFlow Lite Integration**: On-device ML model for instant detection
- **10+ Disease Classes**: Detects common crop diseases
- **Image Analysis**: Take photo or select from gallery
- **Detailed Results**: Disease name, confidence score, description
- **Treatment Recommendations**: Causes, solutions, prevention tips
- **Multiple Model Support**: Switch between detection models

### 4. **Community & Social Features**
#### Posts & Feed
- Share farming experiences and knowledge
- Image upload support
- Community engagement with likes and comments
- Filter posts by: All, Your City, Verified, Pending
- Expert posts highlighting
- Saved posts feature
- Endorsement system (ASHA, Panchayat, Government)

#### Leaderboard System
- Real-time ranking based on community contributions
- Points earned for: Posts, Likes, Endorsements
- Visual podium display for top 3 farmers
- Detailed user statistics
- Personal score tracking
- Recent posts preview

### 5. **AI Chat Assistant**
#### Server-Based Chat
- Conversational AI for farming queries
- Context-aware responses about crops, weather, diseases
- Multi-turn conversations with history
- Message translation support
- Markdown formatting for responses
- YouTube video integration in responses
- URL references and metadata
- Save and resume conversations

#### Offline AI Chat
- Fully offline LLaMA model integration
- Works without internet connection
- Multiple model downloads available
- Local inference on device

### 6. **Voice Assistant**
- Voice-to-text input for queries
- Text-to-speech responses
- Hands-free operation for farmers
- Real-time speech recognition
- Multi-language voice support

### 7. **Government Schemes Portal**
- Browse agricultural schemes
- Filter by: Category, State, Department, Target Group
- Search functionality
- Detailed scheme information
- Official scheme links
- WebView integration for scheme websites
- Tag-based filtering system

### 8. **Mandi Prices**
- Real-time market prices from e-NAM (National Agriculture Market)
- State and district-wise data
- Commodity search
- Price trends: Min, Max, Modal prices
- Arrival quantities
- Market-specific information
- Historical price data

### 9. **Satellite View**
- Satellite imagery integration
- Geographic visualization
- Crop monitoring capabilities

### 10. **Translation Services**
#### Online Translation
- Real-time text translation
- Support for Indian languages
- Context-aware translation
- Batch translation support
- Translation with agricultural context

#### Offline Translation
- Downloadable language models
- Works without internet
- Multiple language pairs
- Indian language focus
- Model management system

---

## 📱 Screen-by-Screen Breakdown

### **Onboarding Screens**
1. **Splash Screen**: Animated logo with language initialization from user profile
2. **Onboarding**: Introduction to app features with Lottie animations
3. **Language Selection**: Choose preferred language (EN/HI/ML)
4. **Location Setup**: Grant location permissions for weather services
5. **Profile Creation**: Name, phone, role, location details

### **Authentication**
- **Login Screen**: Phone number authentication via Firebase
- Supabase backend integration for user management

### **Home Screen**
Central hub with 12 feature cards:
- Weather Forecast
- Share Post
- Community Posts
- MyScheme (Government Schemes)
- IMD Weather
- Disease Detector
- Offline AI Chat
- Saved Posts
- Satellite View
- Test Translation
- Translation Tools
- Mandi Prices

Search bar for quick crop information access

### **Profile Screen**
- Personal information display and editing
- Location preferences (City, State)
- IMD weather station preferences
- Language settings
- Translation model management
- Account information (Member since date)
- Logout functionality

### **Weather Screens**
1. **Weather Forecast Screen**
   - Current weather conditions
   - 7-day forecast with daily temperature ranges
   - Detailed metrics: Humidity, wind, pressure
   - City management (Add/Remove/Switch)
   - Location-based auto-detection

2. **IMD Weather Screen**
   - Official government weather data
   - State and station selection
   - Temperature, rainfall, wind, cloud cover
   - Station management sheet
   - Historical data access

### **Community Screens**
1. **Posts Feed**
   - Scroll through community posts
   - Filter options (All/City/Verified/Pending)
   - Like and comment functionality
   - Save posts for later
   - Expert post badges

2. **Create Post**
   - Add description
   - Upload images
   - Submit for verification

3. **Comments Screen**
   - View all comments on a post
   - Add new comments
   - Real-time updates

4. **Saved Posts**
   - Access bookmarked posts
   - Remove from saved collection

5. **Expert Posts**
   - Filter for verified expert content
   - Agricultural advice from professionals

6. **Leaderboard**
   - Community ranking system
   - Top 3 podium display
   - User rank card with score
   - Detailed statistics (Posts, Likes, Endorsements)
   - Recent posts preview

### **AI & Chat Screens**
1. **Server Chat**
   - AI-powered farming assistant
   - Conversation history
   - Create new chats
   - Message translation
   - Rich responses with links and videos

2. **Chat History**
   - View all past conversations
   - Resume previous chats
   - Delete conversations

3. **Offline AI Chat**
   - Local LLaMA model inference
   - Download models (various sizes)
   - Fully offline functionality

4. **Voice Assistant**
   - Press-and-hold to speak
   - Real-time voice recognition
   - Spoken responses
   - Visual feedback (Listening/Processing/Speaking)

### **Plant Disease Detection Screen**
- Model selection dropdown
- Camera capture option
- Gallery image selection
- Real-time analysis with loading state
- Results display:
  - Disease name
  - Confidence percentage
  - Detailed description
  - Causes
  - Treatment solutions
  - Prevention tips

### **Schemes Screens**
1. **Schemes Browser**
   - Grid/List view of schemes
   - Search functionality
   - Filter sheet with multiple criteria
   - Category-based organization

2. **Scheme Details**
   - Full scheme information
   - Eligibility criteria
   - Benefits
   - How to apply
   - Official links

3. **Scheme WebView**
   - In-app browser for official scheme websites
   - Full navigation controls

### **Mandi Prices Screens**
1. **State Selection**
   - Choose state for market data
   - Visual state list

2. **Mandi Prices Display**
   - District and market selection
   - Commodity search
   - Price table with:
     - Commodity name
     - Min/Max/Modal prices
     - Arrival quantity
     - Date

### **Translation Screens**
1. **Test Translation**
   - Real-time translation demo
   - Language selection
   - Input and output display

2. **Test Offline Translation**
   - Offline model testing
   - Download language models
   - Model management (Download/Delete)
   - Indian languages and others

### **Satellite View Screen**
- Geographic satellite imagery
- Interactive map interface
- Crop monitoring visualization

### **Settings & Configuration**
1. **Language Settings**
   - Change app language
   - Preview translations
   - Save preferences

2. **Model Download Screen**
   - Browse available AI models
   - Download offline AI models
   - Manage installed models
   - Storage management

### **Permission Screen**
- Request location permissions
- Request microphone permissions
- Educational information about why permissions are needed

---

## 🔧 Technical Architecture

### **Frontend**
- **Framework**: Flutter 3.x with Dart
- **State Management**: Provider pattern
- **Routing**: GoRouter for navigation
- **UI Components**: Material Design 3
- **Animations**: Lottie, Animate_do
- **Localization**: Flutter Intl (190+ translation keys)

### **Backend Services**
- **Authentication**: Firebase Auth (Phone OTP)
- **Database**: Supabase (PostgreSQL)
- **Cloud Functions**: Firebase Cloud Functions
- **Push Notifications**: Firebase Cloud Messaging (FCM)

### **AI/ML Integration**
- **On-Device ML**: TensorFlow Lite for disease detection
- **LLM Integration**: LLaMA models (fllama package)
- **Translation**: Custom translation API + offline models
- **Speech**: Flutter TTS, Speech-to-Text

### **APIs & Data Sources**
- **Weather**: OpenWeatherMap API
- **IMD Data**: India Meteorological Department API
- **Mandi Prices**: e-NAM (National Agriculture Market)
- **Government Schemes**: Custom backend aggregation
- **Geolocation**: LocationIQ, Geolocator
- **Satellite**: Custom satellite imagery service

### **Local Storage**
- **Hive**: Offline data caching
- **SharedPreferences**: User preferences
- **File Storage**: Downloaded models, images

### **Key Packages**
```yaml
- provider (State management)
- go_router (Navigation)
- supabase_flutter (Backend)
- firebase_core, firebase_auth (Authentication)
- geolocator, geocoding (Location)
- tflite_flutter (ML models)
- fllama (Offline LLM)
- speech_to_text, flutter_tts (Voice)
- lottie, animate_do (Animations)
- image_picker (Camera/Gallery)
- url_launcher (External links)
- hive, hive_flutter (Local database)
```

---

## 🌾 Use Cases & Benefits

### **For Individual Farmers**
1. **Weather Planning**: Make informed decisions about planting and harvesting
2. **Disease Management**: Early disease detection saves crops
3. **Market Intelligence**: Get best prices for produce
4. **Expert Guidance**: 24/7 AI assistant for farming queries
5. **Community Support**: Learn from other farmers' experiences
6. **Scheme Awareness**: Access government benefits

### **For Farming Communities**
1. **Knowledge Sharing**: Build collective wisdom
2. **Best Practices**: Verified expert posts
3. **Recognition**: Leaderboard rewards active contributors
4. **Local Networking**: Connect with nearby farmers

### **For Agricultural Advisors**
1. **Reach**: Engage with farmer community at scale
2. **Content Distribution**: Share advice through posts
3. **Verified Status**: Expert badges build trust

---

## 🎯 Unique Selling Points

1. **Multilingual**: True localization for rural Indian farmers (EN/HI/ML)
2. **Offline Capable**: AI and translation work without internet
3. **Comprehensive**: 12+ features in one app
4. **Government Integration**: Official IMD data and schemes
5. **Community Driven**: Social features build farmer networks
6. **AI-Powered**: Modern ML for disease detection and chat
7. **Voice Enabled**: Accessibility for low-literacy users
8. **Free to Use**: No subscription fees

---

## 📊 App Statistics
- **190+ Localized Strings** across 3 languages
- **12 Major Features** accessible from home screen
- **49+ Screens** covering all functionality
- **10+ Disease Detection Classes** in ML model
- **30+ Government Scheme Filters**
- **All India Coverage** for weather and mandi prices

---

## 🚀 Future Roadmap
- Crop recommendation system
- Soil testing integration
- Drone imagery analysis
- Marketplace for produce
- Loan and insurance information
- Weather alerts and notifications
- Peer-to-peer equipment sharing
- Video tutorials library

---

## 📱 Platform Support
- **Android**: Full support (API 21+)
- **iOS**: Full support (iOS 12+)
- **Optimized for**: Rural connectivity conditions

---

## 🤝 Target Audience
- Small and marginal farmers
- Agricultural cooperatives
- Rural farming communities
- Agricultural extension workers
- ASHA workers
- Panchayat members
- Government agricultural departments

---

**Krishi Sakha** - Empowering farmers with technology, one harvest at a time! 🌾📱
