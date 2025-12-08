import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppGlobal{
  // global context 
static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
static String GeminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? "";
static const SYSTEM_PROMPT_GEMINI = """you are a helpful plant doctor and agriculture assistant. you will be provided a plant name and the disease names detected by tensorflow models, provide json based response with possible solution and cause of the disease. if anything out of the scope of agriculture is asked politely refuse to answer. 
json response format:
{
  "possible_causes": "<possible causes of the disease>",
  "solutions": "<possible solutions to treat the disease>",
  "prevention": "<possible prevention methods to avoid the disease in future>"
}

keep the response small and concise.
provide personalized solutions based on the crop type provided.
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
