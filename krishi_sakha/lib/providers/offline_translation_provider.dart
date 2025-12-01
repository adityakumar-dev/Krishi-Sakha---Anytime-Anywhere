import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import '../models/translation_model_info.dart';
import '../services/google_translation_service.dart';

/// Provider for managing OFFLINE translation models and settings using Google ML Kit
class OfflineTranslationProvider extends ChangeNotifier {
  final GoogleTranslationService _service = GoogleTranslationService();

  // Model states
  final Map<TranslateLanguage, TranslationModelInfo> _models = {};
  
  // Current translation settings
  TranslateLanguage _sourceLanguage = TranslateLanguage.english;
  TranslateLanguage? _targetLanguage;
  
  // Loading states
  bool _isInitializing = true;
  bool _isTranslating = false;
  String? _lastError;

  // Getters
  bool get isInitializing => _isInitializing;
  bool get isTranslating => _isTranslating;
  String? get lastError => _lastError;
  TranslateLanguage get sourceLanguage => _sourceLanguage;
  TranslateLanguage? get targetLanguage => _targetLanguage;

  List<TranslationModelInfo> get allModels => _models.values.toList();
  List<TranslationModelInfo> get indianModels => 
      _models.values.where((m) => AvailableLanguages.indianLanguages.any((i) => i.language == m.language)).toList();
  List<TranslationModelInfo> get otherModels => 
      _models.values.where((m) => AvailableLanguages.otherLanguages.any((i) => i.language == m.language)).toList();
  List<TranslationModelInfo> get downloadedModels => 
      _models.values.where((m) => m.isDownloaded).toList();

  TranslationModelInfo? get currentTargetModel => 
      _targetLanguage != null ? _models[_targetLanguage] : null;

  OfflineTranslationProvider() {
    _initializeModels();
  }

  /// Initialize models list with their status
  Future<void> _initializeModels() async {
    _isInitializing = true;
    notifyListeners();

    try {
      // Initialize all available language models
      for (final info in AvailableLanguages.allLanguages) {
        _models[info.language] = TranslationModelInfo(
          language: info.language,
          name: info.name,
          nativeName: info.nativeName,
          flagEmoji: info.flagEmoji,
          languageCode: info.languageCode,
        );
      }

      // Check download status for each
      await refreshModelStatuses();

      // Set default target language based on system locale
      await _setDefaultTargetLanguage();

    } catch (e) {
      debugPrint('❌ Error initializing offline translation provider: $e');
      _lastError = e.toString();
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Set default target language based on system locale
  Future<void> _setDefaultTargetLanguage() async {
    try {
      // Get system locale
      final locale = Platform.localeName; // e.g., "hi_IN", "en_US"
      final languageCode = locale.split('_').first.toLowerCase();
      
      debugPrint('📱 System locale: $locale, language code: $languageCode');

      // Find matching language
      final matchingModel = AvailableLanguages.getByCode(languageCode);
      
      if (matchingModel != null && matchingModel.language != TranslateLanguage.english) {
        _targetLanguage = matchingModel.language;
        debugPrint('🎯 Default target language set to: ${matchingModel.name}');
      } else {
        // Default to Hindi if no match
        _targetLanguage = TranslateLanguage.hindi;
        debugPrint('🎯 Default target language set to: Hindi');
      }
    } catch (e) {
      debugPrint('⚠️ Could not detect system language, defaulting to Hindi');
      _targetLanguage = TranslateLanguage.hindi;
    }
  }

  /// Refresh status of all models
  Future<void> refreshModelStatuses() async {
    try {
      for (final language in _models.keys) {
        final isDownloaded = await _service.isModelDownloaded(language);
        _models[language] = _models[language]!.copyWith(
          status: isDownloaded ? ModelDownloadStatus.downloaded : ModelDownloadStatus.notDownloaded,
          downloadProgress: isDownloaded ? 1.0 : 0.0,
        );
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing model statuses: $e');
    }
  }

  /// Download a specific language model
  Future<bool> downloadModel(TranslateLanguage language) async {
    if (!_models.containsKey(language)) return false;

    _lastError = null;
    _models[language] = _models[language]!.copyWith(
      status: ModelDownloadStatus.downloading,
      downloadProgress: 0.0,
    );
    notifyListeners();

    try {
      // Also ensure English is downloaded (required as source)
      if (language != TranslateLanguage.english) {
        final englishDownloaded = await _service.isModelDownloaded(TranslateLanguage.english);
        if (!englishDownloaded) {
          debugPrint('📥 Also downloading English (required as source)...');
          await _service.downloadModel(TranslateLanguage.english);
          // Update English model status
          if (_models.containsKey(TranslateLanguage.english)) {
            _models[TranslateLanguage.english] = _models[TranslateLanguage.english]!.copyWith(
              status: ModelDownloadStatus.downloaded,
              downloadProgress: 1.0,
            );
          }
        }
      }

      // Download the requested model
      final success = await _service.downloadModel(language);

      // Update model status based on result
      _models[language] = _models[language]!.copyWith(
        status: success ? ModelDownloadStatus.downloaded : ModelDownloadStatus.failed,
        downloadProgress: success ? 1.0 : 0.0,
        errorMessage: success ? null : 'Failed to download model',
      );
      
      if (!success) {
        _lastError = 'Failed to download model';
      }
      
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('❌ Error downloading model: $e');
      _models[language] = _models[language]!.copyWith(
        status: ModelDownloadStatus.failed,
        downloadProgress: 0.0,
        errorMessage: e.toString(),
      );
      _lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a downloaded model
  Future<bool> deleteModel(TranslateLanguage language) async {
    if (!_models.containsKey(language)) return false;

    // Don't allow deleting English (required as source)
    if (language == TranslateLanguage.english) {
      _lastError = 'Cannot delete English model (required as source)';
      notifyListeners();
      return false;
    }

    final success = await _service.deleteModel(language);
    
    if (success) {
      _models[language] = _models[language]!.copyWith(
        status: ModelDownloadStatus.notDownloaded,
        downloadProgress: 0.0,
      );
      
      // If this was the target language, clear it
      if (_targetLanguage == language) {
        _targetLanguage = null;
      }
      
      notifyListeners();
    }
    
    return success;
  }

  /// Set target language for translation
  void setTargetLanguage(TranslateLanguage language) {
    _targetLanguage = language;
    notifyListeners();
  }

  /// Set source language for translation
  void setSourceLanguage(TranslateLanguage language) {
    _sourceLanguage = language;
    notifyListeners();
  }

  /// Translate text to current target language
  Future<String> translate(String text) async {
    if (_targetLanguage == null) {
      throw Exception('No target language set');
    }

    // Check if target model is downloaded
    final targetModel = _models[_targetLanguage];
    if (targetModel == null || !targetModel.isDownloaded) {
      throw Exception('Please download the ${targetModel?.name ?? 'target'} language model first');
    }

    _isTranslating = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _service.translate(
        text,
        source: _sourceLanguage,
        target: _targetLanguage!,
      );
      return result;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Translate to a specific language
  Future<String> translateTo(String text, TranslateLanguage target) async {
    _isTranslating = true;
    _lastError = null;
    notifyListeners();

    try {
      final result = await _service.translate(
        text,
        source: _sourceLanguage,
        target: target,
      );
      return result;
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    } finally {
      _isTranslating = false;
      notifyListeners();
    }
  }

  /// Translate using language code
  Future<String> translateByCode(String text, String targetCode) async {
    final modelInfo = AvailableLanguages.getByCode(targetCode);
    if (modelInfo == null) {
      throw Exception('Unknown language code: $targetCode');
    }
    return translateTo(text, modelInfo.language);
  }

  /// Check if translation is available for current settings
  bool get canTranslate {
    if (_targetLanguage == null) return false;
    final targetModel = _models[_targetLanguage];
    final sourceModel = _models[_sourceLanguage];
    return targetModel?.isDownloaded == true && sourceModel?.isDownloaded == true;
  }

  /// Get model info by language
  TranslationModelInfo? getModel(TranslateLanguage language) => _models[language];

  /// Get model info by code
  TranslationModelInfo? getModelByCode(String code) {
    final langInfo = AvailableLanguages.getByCode(code);
    if (langInfo == null) return null;
    return _models[langInfo.language];
  }

  /// Clear any error
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
