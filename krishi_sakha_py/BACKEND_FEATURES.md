# Krishi Sakha Backend Features

**Intelligent Agricultural Advisory System** powered by multi-source context retrieval and AI processing.

## Core Capabilities

**Multi-Language Support**: Malayalam, Hindi, English with automatic translation and context-aware query processing.

**Conversation Memory**: Maintains context across chat sessions, understands follow-up questions and pronouns.

**Smart Query Routing**: Gemini 2.5 Flash analyzes queries and automatically selects relevant data sources.

**Real-Time Data Sources**:
- **Vector DB**: agricultural PDFs from KAU research eg : pop2016.pdf
- **IMD Weather**: 6-day forecasts with 243+ weather stations across India
- **eNAM Prices**: Live mandi commodity prices with 7-day fallback
- **MyScheme**: 67+ government schemes with AI-powered optimization
- **YouTube**: Farming tutorial videos with HTML scraping
- **Web Search**: SearxNG + Playwright for latest information

**Location Intelligence**: GPS-based nearest station finder, automatic state detection, user preference prioritization.

**Voice Mode**: TTS-optimized responses (50-100 words), no special characters, conversational tone.

**Image Analysis**: Gemini 2.0 Flash vision for plant disease detection.

**Response Streaming**: Server-Sent Events for real-time status updates and progressive text generation.

**Smart Features**: Exponential backoff retry, automatic date fallback, parallel processing, state name normalization.

**API**: RESTful FastAPI with JWT authentication, comprehensive error handling, metadata tracking.
