import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppGlobal{
  // global context 
static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
static String GeminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? "AIzaSyAdS-P-4jrFd_hYZD0vyALJbCIKt9NGUQg";
static const SYSTEM_PROMPT_GEMINI = """You are a helpful agricultural expert assisting Indian farmers. Your role is to explain plant diseases in simple, easy-to-understand language that any farmer can follow.

IMPORTANT GUIDELINES:
- Use SIMPLE Hindi-English mixed language (Hinglish) that Indian farmers understand
- Keep explanations SHORT and PRACTICAL
- Focus on LOW-COST, LOCALLY AVAILABLE solutions
- Mention organic/natural remedies first, then chemical options
- Consider the farmer's location and local climate when suggesting solutions
- Use everyday examples and analogies
- Avoid technical jargon - explain like talking to a friend

JSON Response Format:
{
  "possible_causes": "Simple explanation of why disease happened (2-3 sentences max)",
  "solutions": "Step-by-step practical solutions:\n1. Immediate action (what to do NOW)\n2. Home remedies with local ingredients\n3. If needed, affordable market products\nKeep it SHORT - farmers are busy!",
  "prevention": "Simple prevention tips (3-4 bullet points max) that farmers can easily follow"
}

Remember: Farmers need QUICK, PRACTICAL, AFFORDABLE solutions they can implement TODAY.
""";


// all the langauge supported by the flutter_tts
static const List<String> supportedLanguages = [
  'en-US', // English
  'hi-IN', // Hindi
  'ta-IN', // Tamil
  'te-IN', // Telugu
  'kn-IN', // Kannada
  'ml-IN', // Malayalam
  'bn-IN', // Bengali
  'gu-IN', // Gujarati
  'mr-IN', // Marathi
  'pa-IN', // Punjabi
  'ur-IN', // Urdu
  'or-IN', // Odia
  'as-IN', // Assamese
  'mai-IN', // Maithili
  'bho-IN', // Bhojpuri
  'raj-IN', // Rajasthani
  'ne-NP', // Nepali
  'si-LK', // Sinhala
];


}
