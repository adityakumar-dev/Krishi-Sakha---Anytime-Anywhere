import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../models/translation_model_info.dart';

/// Callback for model status changes
typedef ModelStatusCallback = void Function(
  TranslateLanguage language,
  ModelDownloadStatus status,
);

/// Google ML Kit Translation Service
/// Handles model downloading, status checking, and translation
class GoogleTranslationService {
  static final GoogleTranslationService _instance = GoogleTranslationService._internal();
  factory GoogleTranslationService() => _instance;
  GoogleTranslationService._internal();

  final OnDeviceTranslatorModelManager _modelManager = OnDeviceTranslatorModelManager();
  
  // Cache of translators to avoid recreating them
  final Map<String, OnDeviceTranslator> _translatorCache = {};
  
  // Callback for UI updates
  ModelStatusCallback? onModelStatusChanged;

  /// Check if a specific language model is downloaded
  Future<bool> isModelDownloaded(TranslateLanguage language) async {
    try {
      return await _modelManager.isModelDownloaded(language.bcpCode);
    } catch (e) {
      debugPrint('❌ Error checking model status for ${language.bcpCode}: $e');
      return false;
    }
  }

  /// Get download status for all available languages
  Future<Map<TranslateLanguage, ModelDownloadStatus>> getAllModelStatuses() async {
    final statuses = <TranslateLanguage, ModelDownloadStatus>{};
    
    for (final modelInfo in AvailableLanguages.allLanguages) {
      try {
        final isDownloaded = await isModelDownloaded(modelInfo.language);
        statuses[modelInfo.language] = isDownloaded 
            ? ModelDownloadStatus.downloaded 
            : ModelDownloadStatus.notDownloaded;
      } catch (e) {
        statuses[modelInfo.language] = ModelDownloadStatus.notDownloaded;
      }
    }
    
    return statuses;
  }

  /// Download a language model
  /// Returns true if download succeeds or model already downloaded
  Future<bool> downloadModel(TranslateLanguage language) async {
    try {
      onModelStatusChanged?.call(language, ModelDownloadStatus.downloading);
      debugPrint('📥 Starting download for ${language.bcpCode}...');

      // Download the model - ML Kit handles everything internally
      final success = await _modelManager.downloadModel(
        language.bcpCode,
        isWifiRequired: false,
      );
      
      if (success) {
        onModelStatusChanged?.call(language, ModelDownloadStatus.downloaded);
        debugPrint('✅ Model downloaded successfully: ${language.bcpCode}');
      } else {
        onModelStatusChanged?.call(language, ModelDownloadStatus.failed);
        debugPrint('❌ Model download failed: ${language.bcpCode}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error downloading model ${language.bcpCode}: $e');
      onModelStatusChanged?.call(language, ModelDownloadStatus.failed);
      return false;
    }
  }

  /// Delete a downloaded model
  Future<bool> deleteModel(TranslateLanguage language) async {
    try {
      // Clear from translator cache
      final keysToRemove = _translatorCache.keys
          .where((key) => key.contains(language.bcpCode))
          .toList();
      
      for (final key in keysToRemove) {
        await _translatorCache[key]?.close();
        _translatorCache.remove(key);
      }

      final success = await _modelManager.deleteModel(language.bcpCode);
      
      if (success) {
        onModelStatusChanged?.call(language, ModelDownloadStatus.notDownloaded);
        debugPrint('🗑️ Model deleted: ${language.bcpCode}');
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Error deleting model ${language.bcpCode}: $e');
      return false;
    }
  }

  /// Translate text from source to target language
  /// Note: ML Kit's translateText() automatically downloads models if needed
  Future<String> translate(
    String text, {
    TranslateLanguage source = TranslateLanguage.english,
    required TranslateLanguage target,
  }) async {
    if (text.trim().isEmpty) return '';

    try {
      final cacheKey = '${source.bcpCode}_${target.bcpCode}';
      
      // Get or create translator
      OnDeviceTranslator translator;
      if (_translatorCache.containsKey(cacheKey)) {
        translator = _translatorCache[cacheKey]!;
      } else {
        translator = OnDeviceTranslator(
          sourceLanguage: source,
          targetLanguage: target,
        );
        _translatorCache[cacheKey] = translator;
      }

      debugPrint('🔄 Translating: "$text"');
      debugPrint('   From: ${source.bcpCode} → ${target.bcpCode}');

      // translateText() will auto-download models if needed
      final result = await translator.translateText(text);
      
      debugPrint('✅ Result: "$result"');
      return result;
    } catch (e) {
      debugPrint('❌ Translation error: $e');
      rethrow;
    }
  }

  /// Translate text using language codes instead of TranslateLanguage
  Future<String> translateByCode(
    String text, {
    String sourceCode = 'en',
    required String targetCode,
  }) async {
    final source = _getLanguageFromCode(sourceCode);
    final target = _getLanguageFromCode(targetCode);

    if (source == null || target == null) {
      throw Exception('Invalid language code');
    }

    return translate(text, source: source, target: target);
  }

  /// Helper to get TranslateLanguage from code
  TranslateLanguage? _getLanguageFromCode(String code) {
    final info = AvailableLanguages.getByCode(code);
    return info?.language;
  }

  /// Ensure English model is always downloaded (base language)
  Future<bool> ensureEnglishModel() async {
    final isDownloaded = await isModelDownloaded(TranslateLanguage.english);
    if (!isDownloaded) {
      return await downloadModel(TranslateLanguage.english);
    }
    return true;
  }

  /// Get list of downloaded models
  Future<List<TranslateLanguage>> getDownloadedModels() async {
    final downloaded = <TranslateLanguage>[];
    
    for (final modelInfo in AvailableLanguages.allLanguages) {
      if (await isModelDownloaded(modelInfo.language)) {
        downloaded.add(modelInfo.language);
      }
    }
    
    return downloaded;
  }

  /// Release all resources
  void dispose() {
    for (final translator in _translatorCache.values) {
      translator.close();
    }
    _translatorCache.clear();
    debugPrint('🧹 GoogleTranslationService disposed');
  }
}
