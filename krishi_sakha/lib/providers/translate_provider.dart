// import 'package:flutter/material.dart';
// import 'package:google_mlkit_translation/google_mlkit_translation.dart';

// class TranslateProvider extends ChangeNotifier {
//   // Supported offline languages (add more if you want)
//   static final List<TranslateLanguage> _supportedLanguages = [
//     TranslateLanguage.english,   // en
//     TranslateLanguage.malayalam, // ml
//     TranslateLanguage.hindi,     // hi
//     // Add others: tamil, telugu, kannada, etc.
//   ];

//   // Current source & target (you can expose setters if needed)
//   TranslateLanguage sourceLanguage = TranslateLanguage.malayalam;
//   TranslateLanguage targetLanguage = TranslateLanguage.english;

//   // Status tracking
//   bool _isModelsReady = false;
//   String _statusMessage = 'Initializing translation models...';
//   double _downloadProgress = 0.0;

//   bool get isModelsReady => _isModelsReady;
//   String get statusMessage => _statusMessage;
//   double get downloadProgress => _downloadProgress;

//   final OfflineTranslatorService _translatorService = OfflineTranslatorService();

//   /// Call this once on app start (e.g., in main() or splash screen)
//   Future<void> initializeModels() async {
//     _updateStatus('Checking translation models...');

//     final List<String> requiredCodes = [
//       sourceLanguage.bcpCode,   // 'ml'
//       targetLanguage.bcpCode,   // 'en'
//     ];

//     await _translatorService.ensureModelsDownloaded(
//       languageCodes: requiredCodes,
//       onProgress: (code, progress) {
//         _downloadProgress = progress;
//         _updateStatus('Downloading $code model... ${(progress * 100).toStringAsFixed(0)}%');
//         notifyListeners();
//       },
//     );

//     _isModelsReady = true;
//     _updateStatus('Translation ready (offline)');
//     notifyListeners();
//   }

//   void _updateStatus(String message) {
//     _statusMessage = message;
//     print('[TranslateProvider] $message');
//   }

//   /// Translate text (fully offline after models are downloaded)
//   Future<String> translate(String text) async {
//     if (!_isModelsReady) {
//       return 'Translation not ready yet';
//     }

//     try {
//       final translator = OnDeviceTranslator(
//         sourceLanguage: sourceLanguage,
//         targetLanguage: targetLanguage,
//       );

//       final result = await translator.translateText(text);
//       await translator.close();
//       return result;
//     } catch (e) {
//       return 'Translation error: $e';
//     }
//   }

//   @override
//   void dispose() {
//     // No need to close model manager — it's singleton & handled by ML Kit
//     super.dispose();
//   }
// }

// /// Service that handles model downloading with progress
// class OfflineTranslatorService {
//   final _modelManager = OnDeviceTranslatorModelManager();

//   Future<void> ensureModelsDownloaded({
//     required List<String> languageCodes,
//     required void Function(String code, double progress) onProgress,
//   }) async {
//     for (String code in languageCodes) {
//       final bool isDownloaded = await _modelManager.isModelDownloaded(code);

//       if (!isDownloaded) {
//         onProgress(code, 0.0);

//         // Optional: Add conditions (Wi-Fi only, etc.)
//         final bool success = await _modelManager.downloadModel(
//           code,
//           isWifiRequired: true, // Prevents huge mobile data usage
//           // onDownloading: (progress) => onProgress(code, progress), // Not available in current version
//         );

//         if (success) {
//           onProgress(code, 1.0);
//         } else {
//           throw Exception('Failed to download model for language: $code');
//         }
//       } else {
//         onProgress(code, 1.0); // Already downloaded
//       }
//     }
//   }
// }