import 'package:flutter/material.dart';
import 'package:onnx_translation/onnx_translation.dart';

/// Translation service using Helsinki-NLP/opus-mt-en-ml ONNX model
/// Translates English text to Malayalam using MarianMT architecture
/// Handles long paragraphs by breaking them into sentences
class OpusOnnxTranslator {
  static final OpusOnnxTranslator _instance = OpusOnnxTranslator._internal();
  factory OpusOnnxTranslator() => _instance;
  OpusOnnxTranslator._internal();

  OnnxModel? _model;
  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if model is readysentence_splitter
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

  /// Robust sentence segmentation using proven regex pattern
  /// Battle-tested approach for production use
  List<String> _segmentSentences(String text) {
    if (text.trim().isEmpty) return [];

    // Normalize whitespace
    String normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Industry-standard sentence boundary detection
    // Splits on . ! ? followed by whitespace and uppercase letter
    final sentenceBoundary = RegExp(
      r'(?<=[.!?])\s+(?=[A-Z])',
      multiLine: true,
    );

    List<String> sentences = normalized.split(sentenceBoundary)
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // If no splits, return whole text as one sentence
    if (sentences.isEmpty) {
      sentences = [normalized];
    }

    debugPrint('🔢 Split into ${sentences.length} sentences');
    for (int i = 0; i < sentences.length; i++) {
      debugPrint('  [$i]: ${sentences[i]}');
    }

    return sentences;
  }

  /// Translate English text to Malayalam (single sentence)
  /// NO CACHING - always fresh translation to prevent memory issues
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
      // Clean and prepare input text (no caching)
      final cleanText = text.trim();
      debugPrint('📝 Translating (NO CACHE): "$cleanText"');
      debugPrint('⏳ Running ONNX model...');
      
      final startTime = DateTime.now();
      
      // Run fresh translation - MarianMT model handles EN->ML
      // No caching to prevent memory buildup and crashes
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

  /// Translate long text with streaming support - shows each sentence as it's translated
  /// NO CACHING - processes fresh each time to prevent memory issues and crashes
  /// 
  /// [text] - English text (single or multiple sentences/paragraphs)
  /// [onSentenceTranslated] - Callback fired after each sentence is translated with partial result
  /// [maxTokens] - Maximum tokens per sentence (default: 256)
  /// 
  /// Returns full translated Malayalam text
  /// 
  /// Example:
  /// ```dart
  /// await translator.translateLongText(
  ///   paragraph,
  ///   onSentenceTranslated: (partial, current, total) {
  ///     setState(() {
  ///       translatedText = partial; // Show streaming result
  ///       progress = '$current/$total sentences';
  ///     });
  ///   },
  /// );
  /// ```
  Future<String> translateLongText(
    String text, {
    Function(String partialResult, int currentSentence, int totalSentences)? onSentenceTranslated,
    int maxTokens = 256,
  }) async {
    if (text.trim().isEmpty) return '';

    debugPrint('📚 Processing long text for translation (STREAMING MODE - NO CACHE)');
    debugPrint('📏 Text length: ${text.length} characters');

    try {
      // Segment text into sentences (no caching)
      final sentences = _segmentSentences(text);
      debugPrint('🔢 Segmented into ${sentences.length} sentence(s)');

      if (sentences.isEmpty) {
        return '';
      }

      // Track translated sentences for streaming display
      final translatedSentences = <String>[];
      
      // Process each sentence with 0.5s delay BETWEEN sentences for stability
      for (int i = 0; i < sentences.length; i++) {
        final sentence = sentences[i];
        debugPrint('📌 [${i + 1}/${sentences.length}] Translating: "$sentence"');
        
        try {
          // Translate one sentence
          final translated = await translate(
            sentence,
            maxTokens: maxTokens,
          );
          
          if (translated.isNotEmpty) {
            translatedSentences.add(translated);
            debugPrint('✅ [${i + 1}/${sentences.length}] Result: "$translated"');
            
            // Stream the result to UI immediately
            if (onSentenceTranslated != null) {
              final partialResult = translatedSentences.join(' ');
              onSentenceTranslated(partialResult, i + 1, sentences.length);
              debugPrint('🔄 UI Updated with ${i + 1}/${sentences.length} sentences');
            }
            
            // Wait 0.5 seconds AFTER showing result, BEFORE next translation
            // This prevents model overload and gives UI time to render
            if (i < sentences.length - 1) {
              debugPrint('⏸️  Waiting 500ms before next sentence...');
              await Future.delayed(const Duration(milliseconds: 500));
            }
          }
        } catch (e) {
          debugPrint('⚠️ Failed to translate sentence ${i + 1}: $e');
          // Wait even on error to prevent rapid retry crashes
          if (i < sentences.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          continue;
        }
      }

      // Final result
      final result = translatedSentences.join(' ');
      debugPrint('✅ Full translation completed: ${result.length} characters');
      
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in translateLongText: $e');
      debugPrint('$stackTrace');
      rethrow;
    }
  }

  /// Translate paragraph with streaming support (alias for translateLongText)
  /// NO CACHING - fresh translation each time
  /// 
  /// [paragraph] - English paragraph or text
  /// [onSentenceTranslated] - Callback for streaming results
  /// [maxTokens] - Maximum tokens per sentence
  /// 
  /// Returns translated Malayalam paragraph
  Future<String> translateParagraph(
    String paragraph, {
    Function(String partialResult, int currentSentence, int totalSentences)? onSentenceTranslated,
    int maxTokens = 256,
  }) async {
    return translateLongText(
      paragraph,
      onSentenceTranslated: onSentenceTranslated,
      maxTokens: maxTokens,
    );
  }

  /// Get sentence count without translation (useful for progress UI)
  int getSentenceCount(String text) {
    return _segmentSentences(text).length;
  }

  /// Get list of sentences (for debugging/preview)
  List<String> getSentences(String text) {
    return _segmentSentences(text);
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
