# Krishi Sakha - Smart Farming App (Quick Reference)

## Overview
AI-powered farming assistant app built with Flutter. Multilingual (English/Hindi/Malayalam) support for Indian farmers.

---

## Core Features

### 1. Weather Services
- **OpenWeather API**: 7-day forecasts, current conditions, multiple cities
- **IMD Weather**: Official Indian Meteorological Department data, state/station selection

### 2. Plant Disease Detection
- TensorFlow Lite on-device ML model (10+ disease classes)
- Camera/gallery image analysis with treatment recommendations

### 3. Community Platform
- **Posts**: Share farming experiences with images, likes, comments
- **Leaderboard**: Ranking system based on contributions (posts/likes/endorsements)
- **Saved Posts**: Bookmark important content

### 4. AI Assistants
- **Server Chat**: Cloud-based conversational AI for farming queries
- **Offline AI**: Local model (works without internet) the native llama.cpp integration
- **Voice Assistant**: Speech-to-text input, text-to-speech responses on any selected indian langauages

### 5. Government Schemes
- Browse agricultural schemes with filters (state, category, department)
- Detailed scheme information with official links 
- webview of the same scheme details on myscheme

### 6. Mandi Prices
- Real-time market prices from e-NAM
- State/district/commodity-wise data (min/max/modal prices)

### 7. Translation
- **Online**: Real-time translation API for Indian languages
- **Offline**: Downloadable translation models using google_ml_kit
- onnx models for offline translation of text between english to malayalam


### 8. Satellite View
- Geographic satellite view for earth.zoom with different map layers

---

## Key Screens

**Home**: 12 feature cards with search bar  
**Profile**: User info, preferences, language settings  
**Weather**: Current + 7-day forecast, city management  
**IMD**: Government weather data, station management  
**Posts**: Community feed with filters (All/City/Verified)  
**Create Post**: Add description + images  
**Leaderboard**: Top farmers ranking with stats  
**Chat**: AI conversation with history  
**Voice**: Press-and-hold voice interface  
**Disease Detection**: Image analysis with results  
**Schemes**: Browse/filter government schemes  
**Mandi**: Market prices by state/district  
**Translation**: Text translation testing  
**Satellite**: Interactive map view

---

## Tech Stack

**Frontend**: Flutter 3.x, Provider (state), GoRouter (navigation)  
**Backend**: Supabase (PostgreSQL), Firebase (Auth + FCM)  
**AI/ML**: TensorFlow Lite, LLaMA (fllama), Speech recognition  
**APIs**: OpenWeatherMap, IMD, e-NAM, Custom translation API  
**Storage**: Hive (local cache), SharedPreferences  
**Location**: Geolocator, LocationIQ

---

## Localization
- **3 Languages**: English, Hindi (हिंदी), Malayalam (മലയാളം)
- **190+ Translation Keys**: Full UI coverage
- **User Preference**: Language persists from profile settings
- **Dynamic Switching**: Change language anytime

---

## App Statistics
- 49+ screens across 12 major features
- 190+ localized strings in 3 languages
- 10+ disease detection classes
- Offline-capable (AI chat + translation)
- Free to use, no subscription

---

## Target Users
Small/marginal farmers, agricultural cooperatives, rural communities, ASHA workers, Panchayat members, agricultural extension workers

---

## Unique Value
✅ Multilingual for rural Indian farmers  
✅ Works offline (AI + translation)  
✅ 12+ features in single app  
✅ Official government data integration  
✅ Community-driven knowledge sharing  
✅ AI-powered (disease detection + chat)  
✅ Voice-enabled for low-literacy users  
✅ Completely free

---

## Architecture Summary
```
┌─────────────────────────────────────────┐
│         Flutter Mobile App              │
│  (Provider + GoRouter + Material 3)     │
├─────────────────────────────────────────┤
│  Features: Weather, Disease, Chat,      │
│  Community, Schemes, Mandi, Translation │
├─────────────────────────────────────────┤
│  AI/ML Layer: TFLite, LLaMA, TTS/STT   │
├─────────────────────────────────────────┤
│  Backend: Supabase + Firebase           │
├─────────────────────────────────────────┤
│  APIs: OpenWeather, IMD, e-NAM, Custom  │
├─────────────────────────────────────────┤
│  Storage: Hive + SharedPreferences      │
└─────────────────────────────────────────┘
```

**Krishi Sakha** - Smart farming for every farmer 🌾
