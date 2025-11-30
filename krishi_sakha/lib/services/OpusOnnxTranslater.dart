import 'package:flutter/material.dart';
import 'package:onnx_translation/onnx_translation.dart';

/// Translation service using Helsinki-NLP/opus-mt-en-ml ONNX model
/// Translates English text to Malayalam using MarianMT architecture
class OpusOnnxTranslator {
  static final OpusOnnxTranslator _instance = OpusOnnxTranslator._internal();
  factory OpusOnnxTranslator() => _instance;
  OpusOnnxTranslator._internal();

  OnnxModel? _model;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if model is ready
  bool get isReady => _isInitialized;

  /// Initialize the ONNX translation model
  /// Call this once at app startup or before first translation
  Future<void> init() async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      _model = OnnxModel();
      
      // Initialize with correct model file paths
      // Package requires encoder_model.onnx and decoder_model.onnx (NOT decoder_with_past)
      await _model!.init(
        encoderAsset: 'assets/model/en_ml/encoder_model.onnx',
        decoderAsset: 'assets/model/en_ml/decoder_model.onnx',
        vocabAsset: 'assets/model/en_ml/vocab.json',
        tokenizerConfigAsset: 'assets/model/en_ml/tokenizer_config.json',
        generationConfigAsset: 'assets/model/en_ml/generation_config.json',
      );

      _isInitialized = true;
      debugPrint('✅ OpusOnnxTranslator initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ OpusOnnxTranslator init failed: $e');
      debugPrint('$stackTrace');
      _isInitialized = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Translate English text to Malayalam
  /// 
  /// [text] - English text to translate
  /// [maxTokens] - Maximum output tokens (default: 256)
  /// 
  /// Returns translated Malayalam text
  Future<String> translate(String text, {int maxTokens = 256}) async {
    if (!_isInitialized) {
      debugPrint('🔄 Model not initialized, initializing now...');
      await init();
    }

    if (_model == null) {
      throw Exception('Translation model not initialized');
    }

    if (text.trim().isEmpty) {
      return '';
    }

    try {
      // Clean and prepare input text
      final cleanText = text.trim();
      debugPrint('📝 Translating: "$cleanText"');
      debugPrint('⏳ Running ONNX model...');
      
      final startTime = DateTime.now();
      
      // Run translation - MarianMT model handles EN->ML automatically
      final result = await _model!.runModel(
        cleanText,
        maxNewTokens: maxTokens,
      );
      
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('✅ Translation completed in ${elapsed}ms');
      debugPrint('📤 Result: "$result"');

      return result.trim();
    } catch (e, stackTrace) {
      debugPrint('❌ Translation error: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Translate multiple sentences/paragraphs
  /// Splits by sentence and translates each for better quality
  Future<String> translateParagraph(String paragraph, {int maxTokens = 256}) async {
    if (paragraph.trim().isEmpty) return '';

    // Split into sentences for better translation quality
    final sentences = paragraph
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (sentences.isEmpty) {
      return await translate(paragraph, maxTokens: maxTokens);
    }

    final translatedParts = <String>[];
    for (final sentence in sentences) {
      final translated = await translate(sentence.trim(), maxTokens: maxTokens);
      if (translated.isNotEmpty) {
        translatedParts.add(translated);
      }
    }

    return translatedParts.join(' ');
  }

  /// Release resources
  void dispose() {
    try {
      _model?.release();
      _model = null;
      _isInitialized = false;
      debugPrint('🧹 OpusOnnxTranslator disposed');
    } catch (e) {
      debugPrint('Error disposing translator: $e');
    }
  }
}
