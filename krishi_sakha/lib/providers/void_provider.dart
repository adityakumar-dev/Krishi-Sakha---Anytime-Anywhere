import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/providers/unified_translation_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum VoiceState {
  idle, // Ready to listen
  listening, // Currently listening to user
  processing, // Processing user input before sending
  streaming, // Receiving response from server
  speaking, // Speaking response back to user
  error, // Error occurred
}

class VoiceProvider extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _speech = SpeechToText();

  String recognizedWord = "";
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  bool _isStreaming = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
  bool get isStreaming => _isStreaming;

  // State management
  VoiceState _currentState = VoiceState.idle;
  VoiceState get currentState => _currentState;

  String _statusMessage = "Ready to listen";
  String get statusMessage => _statusMessage;

  bool _hasError = false;
  bool get hasError => _hasError;

  String _errorMessage = "";
  String get errorMessage => _errorMessage;

  // Prevent concurrent operations
  bool _isProcessing = false;
  Timer? _listeningTimeout;
  Timer? _speakingTimeout;

  double speechRate = 1.0;

  String _language = 'en-US';
  String _hindiLanguage = "hi-IN";
  String get language => _language;
  String get hindiLanguage => _hindiLanguage;

  // User preferences for voice chat
  String? _userState;
  String? _userStationId;
  String? _userPreferredLanguage; // Language code like 'en-US', 'ml-IN', etc.

  // Translation service - unified online/offline translation
  UnifiedTranslationProvider? _translator;
  bool _isTranslatorInitialized = false;

  // Improved response handling with translation
  final List<String> _pendingSentences = []; // English sentences to translate
  final List<String> _pendingTranslatedSentences =
      []; // Translated sentences to speak
  String _currentBuffer = "";
  String lastResponse = ""; // Full English response
  String lastTranslatedResponse = ""; // Full translated response

  // Sentence boundary markers
  static const _sentenceEnders = ['.', '!', '?', '।', '॥'];
  static const _minSentenceLength = 15;

  // JSON buffer for handling streaming data
  String _incompleteJsonBuffer = '';

  // Metadata from response
  Map<String, dynamic> _currentMetadata = {};
  Map<String, dynamic> get currentMetadata => _currentMetadata;

  VoiceProvider() {
    _initializeSpeech();

    // Listen when current utterance finishes => start next one
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      if (_pendingTranslatedSentences.isNotEmpty) {
        _speakNext();
      } else {
        _setIdle();
      }
    });

    // Handle TTS errors
    _tts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _isSpeaking = false;
      _handleError('TTS Error: $msg');
      if (_pendingTranslatedSentences.isNotEmpty) {
        _speakNext();
      }
    });
  }

  // Set user preferences from ProfileProvider
  void setUserPreferences({
    String? state,
    String? stationId,
    String? preferredLanguage,
  }) {
    _userState = state;
    _userStationId = stationId;
    _userPreferredLanguage = preferredLanguage;

    // Set both STT and TTS language
    if (preferredLanguage != null) {
      _language = preferredLanguage; // Set speech recognition language
      _tts.setLanguage(preferredLanguage); // Set TTS language
      debugPrint(
        '🌐 [VoiceProvider] STT & TTS language set to: $preferredLanguage',
      );

      // Initialize translator if needed (currently only for Malayalam)
      if (preferredLanguage == 'ml-IN' && !_isTranslatorInitialized) {
        _initializeTranslator();
      }
    }

    notifyListeners();
  }

  Future<void> _initializeTranslator() async {
    if (_isTranslatorInitialized) return;

    try {
      debugPrint('🔄 [VoiceProvider] Initializing unified translator...');
      _translator = UnifiedTranslationProvider();
      await _translator!.initializeOfflineTranslation();
      _isTranslatorInitialized = true;
      debugPrint('✅ [VoiceProvider] Translator initialized successfully');
    } catch (e) {
      debugPrint('❌ [VoiceProvider] Translator initialization failed: $e');
      _isTranslatorInitialized = false;
    }
  }

  Future<void> _initializeSpeech() async {
    try {
      debugPrint('🎤 [VoiceProvider] ===== INITIALIZATION START =====');
      _statusMessage = "Initializing speech recognition...";
      notifyListeners();

      debugPrint('🎤 [VoiceProvider] Calling _speech.initialize()...');
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint(
            '❌ [VoiceProvider] Speech onError callback during init: error=$error',
          );
          if (!_isInitialized && !_hasError) {
            _handleError('Speech error: $error');
            notifyListeners();
          }
        },
        onStatus: (status) {
          debugPrint(
            '📊 [VoiceProvider] Speech onStatus callback: status=$status',
          );
        },
      );

      debugPrint(
        '🎤 [VoiceProvider] _speech.initialize() returned: $_isInitialized',
      );

      if (_isInitialized) {
        debugPrint(
          '✅ [VoiceProvider] Speech recognition initialized successfully',
        );

        try {
          debugPrint('🎤 [VoiceProvider] Configuring TTS...');
          await _tts.setPitch(1.0);
          await _tts.setSpeechRate(0.5);
          debugPrint('✅ [VoiceProvider] TTS configured (pitch=1.0, rate=0.5)');
        } catch (e) {
          debugPrint('⚠️ [VoiceProvider] TTS config warning: $e');
        }

        _statusMessage = "Ready to listen";
        _currentState = VoiceState.idle;
        debugPrint('✅ [VoiceProvider] State set to IDLE');
      } else {
        debugPrint(
          '❌ [VoiceProvider] Speech recognition initialization FAILED',
        );
        _statusMessage = "Failed to initialize";
        _handleError("Failed to initialize speech recognition");
      }

      debugPrint('🎤 [VoiceProvider] ===== INITIALIZATION END =====');
      notifyListeners();
    } catch (e) {
      debugPrint(
        '❌ [VoiceProvider] Initialization exception: $e (type: ${e.runtimeType})',
      );
      _statusMessage = "Initialization error";
      _handleError('Initialization error: $e');
      notifyListeners();
    }
  }

  void setLanguage(String lang) {
    _language = lang;
    _tts.setLanguage(lang);
    debugPrint('🌐 [VoiceProvider] Language set to: $lang');
    notifyListeners();
  }

  Future<void> startListening() async {
    debugPrint(
      '🎤 [VoiceProvider] startListening called - isProcessing: $_isProcessing, isInitialized: $_isInitialized, isListening: $_isListening',
    );

    // Prevent concurrent operations
    if (_isProcessing || _isListening) {
      debugPrint(
        '⚠️ [VoiceProvider] Already in progress (processing=$_isProcessing, listening=$_isListening), skipping start listen',
      );
      if (!_hasError) {
        _handleError("Already processing. Please wait.");
      }
      return;
    }

    if (!_isInitialized) {
      debugPrint('🎤 [VoiceProvider] Not initialized, initializing now...');
      await _initializeSpeech();
    }

    if (!_isInitialized) {
      debugPrint('❌ [VoiceProvider] Still not initialized after init attempt');
      _handleError("Speech recognition not available");
      return;
    }

    debugPrint('🎤 [VoiceProvider] Proceeding with listen setup...');

    // Cancel any existing operations
    _listeningTimeout?.cancel();

    recognizedWord = "";
    lastResponse = ""; // Clear previous response when starting new voice input
    lastTranslatedResponse = ""; // Clear previous translated response
    _currentMetadata = {}; // Clear previous metadata
    debugPrint(
      '🧹 [VoiceProvider] Cleared previous response text for new voice input',
    );

    _isListening = true;
    _isProcessing = true;
    _currentState = VoiceState.listening;
    _statusMessage = "Listening... (max 30 seconds)";
    _hasError = false;
    _errorMessage = "";
    notifyListeners();

    debugPrint('🎤 [VoiceProvider] Set initial state - notifyListeners sent');

    // Set timeout for listening - don't auto-stop, just log when time is up
    _listeningTimeout = Timer(const Duration(seconds: 35), () {
      debugPrint("⏰ [VoiceProvider] 35-second timeout reached");
      if (_isListening && recognizedWord.isEmpty) {
        debugPrint(
          "⏰ [VoiceProvider] No speech yet after 35s - stopping listening",
        );
        stopListening();
      }
    });

    try {
      debugPrint(
        '🎤 [VoiceProvider] About to call _speech.listen() with locale: $_language, listenFor: 30s, pauseFor: 3s',
      );

      bool hasReceivedResult = false;

      try {
        debugPrint('📝 [VoiceProvider] Calling _speech.listen()...');
        debugPrint("Selected Language: $_language");
        // Call listen - the return value indicates if listening started
        // Note: This might return null on some platforms, so we check nullable bool
        final dynamic listenResult = await _speech
            .listen(
              onResult: (result) {
                debugPrint(
                  '📝 [VoiceProvider] onResult FIRED - words="${result.recognizedWords}", isFinal=${result.finalResult}, confidence=${result.confidence}',
                );

                if (!_isListening) {
                  debugPrint(
                    '📝 [VoiceProvider] onResult called but isListening=false, ignoring',
                  );
                  return;
                }

                hasReceivedResult = true;
                recognizedWord = result.recognizedWords;

                if (!result.finalResult) {
                  _statusMessage =
                      "Listening: ${recognizedWord.isNotEmpty ? recognizedWord : '(waiting for speech...)'}";
                  debugPrint(
                    '🔄 [VoiceProvider] Partial result: "$recognizedWord"',
                  );
                } else {
                  debugPrint(
                    '✅ [VoiceProvider] FINAL result received: "$recognizedWord"',
                  );
                  _listeningTimeout?.cancel();
                  debugPrint(
                    '✅ [VoiceProvider] Stopped listening timeout, now calling stopListening()',
                  );
                  stopListening();
                }
                notifyListeners();
              },
              listenFor: const Duration(seconds: 30),
              pauseFor: const Duration(seconds: 3),
              localeId: _language,
              onSoundLevelChange: (double level) {
                if (level > 0.5) {
                  debugPrint('🔊 [VoiceProvider] Sound level: $level');
                }
              },
              listenOptions: SpeechListenOptions(
                partialResults: true,
                cancelOnError: false,
                listenMode: ListenMode.confirmation,
              ),
            )
            .timeout(
              const Duration(seconds: 40),
              onTimeout: () {
                debugPrint('⏰ [VoiceProvider] listen() call timeout after 40s');
                return null;
              },
            );

        debugPrint(
          '🎤 [VoiceProvider] _speech.listen() returned: $listenResult (type: ${listenResult.runtimeType}), hasReceivedResult: $hasReceivedResult',
        );

        // Handle the return value - it can be bool or null
        if (listenResult is bool) {
          if (!listenResult) {
            if (hasReceivedResult) {
              debugPrint(
                '📝 [VoiceProvider] listen() returned false but we got a result - probably normal completion',
              );
            } else {
              debugPrint(
                '❌ [VoiceProvider] listen() returned false and no results received - listening may have failed to start',
              );
              if (_isListening) {
                _handleError(
                  "Failed to start listening. Ensure microphone permissions are enabled.",
                );
                _isListening = false;
                _isProcessing = false;
                _listeningTimeout?.cancel();
                _setIdle();
              }
            }
          } else {
            debugPrint(
              '✅ [VoiceProvider] listen() returned true - listening is active',
            );
          }
        } else if (listenResult == null) {
          debugPrint(
            '📝 [VoiceProvider] listen() returned null - waiting for result callbacks',
          );
          // On some platforms, listen() returns null but callbacks will fire
          if (!hasReceivedResult) {
            debugPrint(
              '⏳ [VoiceProvider] No result callback yet, listening may still be active',
            );
          }
        } else {
          debugPrint(
            '⚠️ [VoiceProvider] listen() returned unexpected type: ${listenResult.runtimeType}',
          );
        }
      } on TimeoutException catch (e) {
        debugPrint('❌ [VoiceProvider] Listen timeout exception: $e');
        _handleError("Listening timeout. Please try again.");
        _isListening = false;
        _isProcessing = false;
        _listeningTimeout?.cancel();
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        '❌ [VoiceProvider] Listen exception: $e (type: ${e.runtimeType})',
      );

      String errorMsg = e.toString();
      if (errorMsg.contains('timeout') ||
          errorMsg.contains('error_speech_timeout')) {
        _handleError("No speech detected in 30 seconds. Please try again.");
      } else if (errorMsg.contains('permission') ||
          errorMsg.contains('Permission') ||
          errorMsg.contains('403')) {
        _handleError(
          "Microphone permission required. Please enable in app settings.",
        );
      } else if (errorMsg.contains('not available') ||
          errorMsg.contains('unavailable')) {
        _handleError("Speech recognition not available on this device.");
      } else if (errorMsg.contains('no_match')) {
        _handleError("Could not understand your speech. Please try again.");
      } else {
        _handleError('Listen error: $errorMsg');
      }

      _isListening = false;
      _isProcessing = false;
      _listeningTimeout?.cancel();
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    debugPrint(
      '🎤 [VoiceProvider] stopListening called - isListening: $_isListening, recognizedWord: "$recognizedWord" (${recognizedWord.length} chars)',
    );

    _listeningTimeout?.cancel();
    _isListening = false; // ✅ Stop listening first

    try {
      debugPrint('🎤 [VoiceProvider] Calling _speech.stop()...');
      await _speech.stop();
      debugPrint('✅ [VoiceProvider] _speech.stop() completed successfully');
    } catch (e) {
      debugPrint('❌ [VoiceProvider] Error calling _speech.stop(): $e');
    }

    // Small delay to let speech recognition fully stop
    await Future.delayed(const Duration(milliseconds: 100));

    debugPrint(
      '📤 [VoiceProvider] stopListening - checking if we have valid recognized text...',
    );

    // Trigger API call if we have recognized text
    if (recognizedWord.isNotEmpty && recognizedWord.length > 2) {
      debugPrint(
        '📤 [VoiceProvider] ✅ Valid speech: "$recognizedWord" (${recognizedWord.length} chars) - calling getResponse()',
      );
      _statusMessage = "Processing your request...";
      _currentState = VoiceState.processing;
      notifyListeners();

      // Don't set _isProcessing = false here - let getResponse() and stream handlers manage it
      await getResponse();
    } else if (recognizedWord.isEmpty) {
      debugPrint('⚠️ [VoiceProvider] No speech recognized (empty text)');
      _handleError("No speech detected. Please try speaking again.");
      _isProcessing = false; // ✅ Reset on failed input
      debugPrint(
        '🔴 [VoiceProvider] No valid speech - reset _isProcessing = false',
      );
      _setIdle();
    } else if (recognizedWord.length <= 2) {
      debugPrint(
        '⚠️ [VoiceProvider] Speech too short: "${recognizedWord}" (${recognizedWord.length} chars, need >2)',
      );
      _handleError("Speech too short. Please try speaking a full sentence.");
      _isProcessing = false; // ✅ Reset on failed input
      debugPrint(
        '🔴 [VoiceProvider] Speech too short - reset _isProcessing = false',
      );
      _setIdle();
    }
  }

  Future<void> getResponse() async {
    debugPrint('🎙️ [VoiceProvider] ===== API CALL START =====');
    debugPrint('🎙️ [VoiceProvider] Received prompt: "$recognizedWord"');

    if (recognizedWord.isEmpty) {
      debugPrint('⚠️ [VoiceProvider] Prompt is empty, returning early');
      _setIdle();
      return;
    }

    try {
      debugPrint('🎙️ [VoiceProvider] Stopping any existing TTS...');
      await _tts.stop();

      lastResponse = "";
      lastTranslatedResponse = "";
      _currentBuffer = "";
      _pendingSentences.clear();
      _pendingTranslatedSentences.clear();
      _processedSentences.clear(); // Clear processed sentences for new request
      _currentMetadata = {};
      _incompleteJsonBuffer = '';
      _isStreaming = true;
      _currentState = VoiceState.streaming;
      _statusMessage = "Receiving response...";
      notifyListeners();
      debugPrint('🎙️ [VoiceProvider] State prepared for streaming');

      final url = '${ApiManager.baseUrl}/chat/agri';
      debugPrint(
        '📤 [VoiceProvider] API URL: $url (using AgriChat with voice=true)',
      );

      final token =
          Supabase.instance.client.auth.currentSession?.accessToken ?? '';
      debugPrint('📤 [VoiceProvider] Auth token present: ${token.isNotEmpty}');
      debugPrint(
        '📤 [VoiceProvider] User preferences - State: $_userState, Station: $_userStationId, Language: $_userPreferredLanguage',
      );

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['prompt'] = recognizedWord;
      request.fields['conversation_id'] = '-1'; // Voice doesn't save
      request.fields['history'] = '[]'; // No history for voice
      request.fields['is_voice'] = 'true'; // Mark as voice request
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['ngrok-skip-browser-warning'] = 'true';

      // Add user preferences for pipeline context
      if (_userState != null && _userState!.isNotEmpty) {
        request.fields['state'] = _userState!;
      }
      if (_userStationId != null && _userStationId!.isNotEmpty) {
        request.fields['station_id'] = _userStationId!;
      }

      debugPrint(
        '📤 [VoiceProvider] Multipart request prepared: prompt="${recognizedWord}", is_voice=true',
      );

      debugPrint('📤 [VoiceProvider] Sending request...');
      final response = await request.send().timeout(
        const Duration(seconds: 90), // Longer timeout for pipeline
        onTimeout: () {
          debugPrint('⏰ [VoiceProvider] Request timeout after 90s');
          throw TimeoutException("API request timeout after 90 seconds");
        },
      );

      debugPrint(
        '📥 [VoiceProvider] Response received: status=${response.statusCode}',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ [VoiceProvider] HTTP 200 - starting to listen to stream');

        int chunkCount = 0;
        int totalChars = 0;

        response.stream
            .transform(utf8.decoder)
            .listen(
              (data) {
                chunkCount++;
                totalChars += data.length;
                debugPrint(
                  '📥 [VoiceProvider] Chunk $chunkCount: ${data.length} chars, total: $totalChars chars',
                );
                handleStreamChunk(data);
              },
              onError: (error) {
                debugPrint(
                  '❌ [VoiceProvider] Stream error: $error (type: ${error.runtimeType})',
                );
                _handleError('Stream error: $error');
                _isStreaming = false;
                _isProcessing = false; // ✅ Always reset on error
                _listeningTimeout?.cancel();
                debugPrint(
                  '🔴 [VoiceProvider] Stream error - reset _isProcessing = false',
                );
                notifyListeners();
              },
              onDone: () {
                debugPrint(
                  '✅ [VoiceProvider] Stream completed - received $chunkCount chunks, $totalChars total chars',
                );
                _isStreaming = false;
                _flushBuffer();
                // ✅ Reset processing flag when stream is done
                // Don't wait for TTS to finish - reset immediately so new requests can start
                _isProcessing = false;
                debugPrint(
                  '🟢 [VoiceProvider] Stream done - reset _isProcessing = false (TTS will complete separately)',
                );
                notifyListeners();
                debugPrint('🎙️ [VoiceProvider] ===== API CALL END =====');
              },
            );
      } else {
        debugPrint('❌ [VoiceProvider] HTTP Error: ${response.statusCode}');
        final responseBody = await response.stream.bytesToString();
        debugPrint('❌ [VoiceProvider] Response body: $responseBody');
        _handleError('Server error: ${response.statusCode}');
        _isStreaming = false;
        _isProcessing = false;
        _setIdle();
      }
    } catch (e) {
      debugPrint(
        '❌ [VoiceProvider] Request exception: $e (type: ${e.runtimeType})',
      );
      _handleError('Request error: $e');
      _isStreaming = false;
      _isProcessing = false;
      _setIdle();
      debugPrint('🎙️ [VoiceProvider] ===== API CALL END (ERROR) =====');
    }
  }

  void handleStreamChunk(String chunk) {
    if (chunk.isEmpty) return;

    _incompleteJsonBuffer += chunk;

    while (true) {
      final newlineIndex = _incompleteJsonBuffer.indexOf('\n');
      if (newlineIndex == -1) break;

      final completeLine = _incompleteJsonBuffer.substring(0, newlineIndex);
      _incompleteJsonBuffer = _incompleteJsonBuffer.substring(newlineIndex + 1);

      _processCompleteLine(completeLine);
    }
  }

  void _processCompleteLine(String line) {
    final trimmedLine = line.trim();
    if (trimmedLine.isEmpty) return;

    String jsonStr = trimmedLine;
    if (jsonStr.startsWith('data: ')) {
      jsonStr = jsonStr.substring(6).trim();
    }

    if (jsonStr.isEmpty || jsonStr == '[DONE]') return;

    debugPrint('🔵 VOICE JSON: $jsonStr');

    try {
      final data = jsonDecode(jsonStr);
      if (data == null || data is! Map<String, dynamic>) return;

      final type = data['type'];
      if (type == null || type is! String) return;

      debugPrint('🟡 VOICE CHUNK TYPE: $type');

      switch (type) {
        case 'status':
          final message = data['message'];
          if (message != null && message is String && message.isNotEmpty) {
            _statusMessage = message;
            notifyListeners();
          }
          break;

        case 'urls':
          final urls = data['urls'];
          debugPrint('📨 RECEIVED URLS: $urls');
          if (urls != null && urls is List) {
            _currentMetadata['urls'] = urls.cast<String>();
            notifyListeners();
          }
          break;

        case 'youtube':
          final results = data['results'];
          debugPrint('📺 RECEIVED YOUTUBE: ${results?.length ?? 0} videos');
          if (results != null && results is List) {
            _currentMetadata['youtube'] = results;
            notifyListeners();
          }
          break;

        case 'text':
          final textChunk = data['chunk'];
          if (textChunk != null && textChunk is String) {
            _processTextChunk(textChunk);
          }
          break;

        case 'complete':
          // Stream completed
          break;

        case 'error':
          final errorMessage = data['message'] ?? 'Unknown error occurred';
          debugPrint('❌ BACKEND ERROR: $errorMessage');
          _handleError(errorMessage);
          break;
      }
    } catch (e) {
      debugPrint('❌ JSON PARSE ERROR: $e for line: $jsonStr');
    }
  }

  void _processTextChunk(String chunk) {
    debugPrint('📥 [CHUNK] Raw: "$chunk"');
    _currentBuffer += chunk;
    debugPrint('📦 [BUFFER] Current buffer: "$_currentBuffer"');
    _checkAndExtractSentences();
    debugPrint(
      '📝 [VoiceProvider] After processing - currentBuffer length: ${_currentBuffer.length}, pending English sentences: ${_pendingSentences.length}, pending translated: ${_pendingTranslatedSentences.length}',
    );
    notifyListeners();
  }

  void _checkAndExtractSentences() {
    // ✅ Find the sentence that ends with any ender character
    int bestIndex = -1;

    // Find which sentence ender comes first
    for (final ender in _sentenceEnders) {
      int index = _currentBuffer.indexOf(ender);
      if (index != -1 && (bestIndex == -1 || index < bestIndex)) {
        bestIndex = index;
      }
    }

    // Process only complete sentences
    while (bestIndex != -1) {
      String sentence = _currentBuffer.substring(0, bestIndex + 1).trim();

      if (sentence.length >= _minSentenceLength) {
        debugPrint('✂️ [EXTRACT] English sentence: "$sentence"');
        _addSentence(sentence);

        // Remove processed sentence from buffer
        _currentBuffer = _currentBuffer.substring(bestIndex + 1).trim();
        debugPrint('📦 [BUFFER] After removal: "$_currentBuffer"');
        debugPrint(
          '✂️ [VoiceProvider] Remaining buffer: "${_currentBuffer.length > 50 ? _currentBuffer.substring(0, 50) + '...' : _currentBuffer}"',
        );

        // Find next sentence ender
        bestIndex = -1;
        for (final ender in _sentenceEnders) {
          int index = _currentBuffer.indexOf(ender);
          if (index != -1 && (bestIndex == -1 || index < bestIndex)) {
            bestIndex = index;
          }
        }
      } else {
        // Sentence too short, but check if we have more content coming
        // If the sentence ended and we have more text after, don't wait - speak it
        if (_currentBuffer.length > bestIndex + 1) {
          // More text exists after this short sentence, speak it anyway
          debugPrint(
            '✂️ [VoiceProvider] Short sentence but more content follows: "$sentence", speaking it',
          );
          _addSentence(sentence);
          _currentBuffer = _currentBuffer.substring(bestIndex + 1).trim();

          // Find next sentence ender
          bestIndex = -1;
          for (final ender in _sentenceEnders) {
            int index = _currentBuffer.indexOf(ender);
            if (index != -1 && (bestIndex == -1 || index < bestIndex)) {
              bestIndex = index;
            }
          }
        } else {
          // Sentence too short and nothing after it, keep waiting for more text
          debugPrint(
            '⏳ [VoiceProvider] Sentence too short (${sentence.length} chars): "$sentence", waiting for more text',
          );
          break;
        }
      }
    }

    // Handle buffer overflow - split into chunks if too long
    if (_currentBuffer.length > 150) {
      debugPrint(
        '⚠️ [VoiceProvider] Buffer overflow (${_currentBuffer.length} chars), splitting into chunks',
      );
      final words = _currentBuffer.split(' ');
      if (words.length > 15) {
        final chunk = words.sublist(0, 15).join(' ');
        debugPrint('✂️ [VoiceProvider] Force-split chunk: "$chunk"');
        _addSentence(chunk);
        _currentBuffer = words.sublist(15).join(' ');
        debugPrint(
          '✂️ [VoiceProvider] Remaining after force-split: "${_currentBuffer.length > 50 ? _currentBuffer.substring(0, 50) + '...' : _currentBuffer}"',
        );
      }
    }
  }

  void _flushBuffer() {
    if (_currentBuffer.trim().isNotEmpty) {
      _addSentence(_currentBuffer.trim());
      _currentBuffer = "";
    }
  }

  // Track already processed sentences to avoid duplicates
  final Set<String> _processedSentences = {};

  void _addSentence(String sentence) {
    if (sentence.isEmpty) return;

    // ✅ Clean up markdown and unwanted characters
    var cleanedSentence = sentence
        // Remove markdown bold: **text** or __text__
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        // Remove markdown italic: *text* or _text_
        .replaceAll(RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'), r'$1')
        .replaceAll(RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'), r'$1')
        // Remove markdown code: `text`
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')
        // Remove markdown code blocks: ```text```
        .replaceAll(RegExp(r'```(.+?)```', dotAll: true), r'$1')
        // Remove markdown headers: # text, ## text, etc.
        .replaceAll(RegExp(r'^#+\s+'), '')
        // Remove markdown links: [text](url)
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1')
        // Remove markdown images: ![alt](url)
        .replaceAll(RegExp(r'!\[(.+?)\]\(.+?\)'), r'$1')
        // Remove markdown lists: - item, * item, + item
        .replaceAll(RegExp(r'^[\s]*[-*+]\s+'), '')
        // Remove markdown numbered lists: 1. item
        .replaceAll(RegExp(r'^\s*\d+\.\s+'), '')
        // Remove markdown horizontal rules: ---, ***, ___
        .replaceAll(RegExp(r'^[\s]*([-*_]){3,}[\s]*$'), '')
        // Remove markdown blockquotes: > text
        .replaceAll(RegExp(r'^>\s+'), '')
        // Remove special characters that shouldn't be spoken
        .replaceAll(RegExp(r'[#$%^&*<>{}|\\~`]'), '')
        // Remove extra whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanedSentence.isEmpty) return;

    // Check if already processed (deduplication)
    if (_processedSentences.contains(cleanedSentence)) {
      debugPrint('⚠️ [DUPLICATE] Skipping: "$cleanedSentence"');
      return;
    }

    debugPrint('✅ [CLEAN] English: "$cleanedSentence"');
    _processedSentences.add(cleanedSentence);
    _pendingSentences.add(cleanedSentence);

    // Translate if needed
    if (_userPreferredLanguage != null && _userPreferredLanguage != 'en-US') {
      _translateAndSpeak(cleanedSentence);
    } else {
      lastResponse += cleanedSentence + ' ';
      lastTranslatedResponse += cleanedSentence + ' ';
      _pendingTranslatedSentences.add(cleanedSentence);
      if (!_isSpeaking) _speakNext();
    }
    notifyListeners();
  }

  Future<void> _translateAndSpeak(String englishSentence) async {
    try {
      final targetLang = _getLanguageCode(_userPreferredLanguage ?? 'en');

      // Use unified translation provider with delay to prevent crashes
      if (_translator == null) {
        await _initializeTranslator();
      }

      String translatedText;
      if (_translator != null) {
        // Add delay between translations to prevent overwhelming ONNX model
        final result = await _translator!.translateText(
          englishSentence,
          targetLanguage: targetLang,
          addDelay: true, // Prevent rapid consecutive translations
        );

        if (result.success) {
          translatedText = result.translation;
          debugPrint(
            '✅ [TRANSLATE] $targetLang (${result.usedOffline ? "offline" : "online"}): "$translatedText"',
          );
        } else {
          // If translation fails, use original English
          debugPrint(
            '⚠️ [TRANSLATE] Failed: ${result.error}, using original text',
          );
          translatedText = englishSentence;
        }
      } else {
        // Fallback to Google Translate if unified translator not available
        debugPrint(
          '⚠️ [TRANSLATE] Unified translator not available, using Google Translate',
        );
        translatedText = await _translateViaGoogle(englishSentence, targetLang);
      }

      lastResponse += translatedText + ' ';
      lastTranslatedResponse += translatedText + ' ';
      _pendingTranslatedSentences.add(translatedText);

      if (!_isSpeaking) _speakNext();
    } catch (e) {
      debugPrint('❌ [TRANSLATE] Failed: $e');
      lastResponse += englishSentence + ' ';
      lastTranslatedResponse += englishSentence + ' ';
      _pendingTranslatedSentences.add(englishSentence);
      if (!_isSpeaking) _speakNext();
    }
  }

  // Google Translate API helper
  Future<String> _translateViaGoogle(String text, String targetLang) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Translation timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null &&
            data is List &&
            data.isNotEmpty &&
            data[0] is List) {
          final translatedParts = data[0] as List;
          final translated = translatedParts
              .map(
                (part) =>
                    part is List && part.isNotEmpty ? part[0].toString() : '',
              )
              .where((text) => text.isNotEmpty)
              .join('');
          return translated.isNotEmpty ? translated : text;
        }
      }

      debugPrint(
        '⚠️ [VoiceProvider] Google Translate returned non-200: ${response.statusCode}',
      );
      return text; // Fallback to original
    } catch (e) {
      debugPrint('❌ [VoiceProvider] Google Translate error: $e');
      return text; // Fallback to original
    }
  }

  // Convert locale code to language code (en-US -> en, hi-IN -> hi)
  String _getLanguageCode(String locale) {
    return locale.split('-').first;
  }

  // Get language name for display
  String _getLanguageName(String code) {
    const names = {
      'hi': 'Hindi',
      'ta': 'Tamil',
      'te': 'Telugu',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'bn': 'Bengali',
      'gu': 'Gujarati',
      'mr': 'Marathi',
      'pa': 'Punjabi',
      'ur': 'Urdu',
      'or': 'Odia',
      'as': 'Assamese',
      'mai': 'Maithili',
      'bho': 'Bhojpuri',
      'raj': 'Rajasthani',
      'ne': 'Nepali',
      'si': 'Sinhala',
      'en': 'English',
    };
    return names[code] ?? code;
  }

  void _speakNext() async {
    if (_pendingTranslatedSentences.isEmpty) {
      _isSpeaking = false;
      _speakingTimeout?.cancel();
      _isProcessing =
          false; // ✅ ALWAYS reset processing flag when done speaking
      debugPrint(
        '🟢 [VoiceProvider] No more sentences to speak - setting _isProcessing = false',
      );
      _setIdle();
      notifyListeners();
      return;
    }

    final nextSentence = _pendingTranslatedSentences.removeAt(0);

    try {
      _isSpeaking = true;
      _currentState = VoiceState.speaking;
      _statusMessage = "Speaking response...";
      notifyListeners();

      // Set timeout for speaking
      _speakingTimeout?.cancel();
      _speakingTimeout = Timer(const Duration(seconds: 120), () {
        debugPrint("Speaking timeout reached");
        cancelSpeaking();
      });

      await _tts.speak(nextSentence);
    } catch (e) {
      debugPrint('TTS Error: $e');
      _handleError('TTS Error: $e');
      _isSpeaking = false;
      _isProcessing = false; // ✅ Reset on error
      _speakingTimeout?.cancel();
      notifyListeners();
      if (_pendingSentences.isNotEmpty) {
        _speakNext();
      }
    }
  }

  void cancelSpeaking() {
    _tts.stop();
    _pendingSentences.clear();
    _currentBuffer = "";
    _isSpeaking = false;
    _isStreaming = false;
    _isProcessing = false;
    _listeningTimeout?.cancel();
    _speakingTimeout?.cancel();
    _setIdle();
  }

  void _setIdle() {
    debugPrint('🟢 [VoiceProvider] Setting state to IDLE');
    _currentState = VoiceState.idle;
    _statusMessage = "Ready to listen";
    _hasError = false;
    _errorMessage = "";
    notifyListeners();
  }

  void _handleError(String message) {
    debugPrint('🔴 [VoiceProvider] ERROR: $message');
    _hasError = true;
    _errorMessage = message;
    _currentState = VoiceState.error;
    _statusMessage = "Error: $message";
    notifyListeners();
  }

  void clearError() {
    debugPrint('🟡 [VoiceProvider] Clearing error');
    _hasError = false;
    _errorMessage = "";
    _setIdle();
  }

  @override
  void dispose() {
    _tts.stop();
    _speech.stop();
    _listeningTimeout?.cancel();
    _speakingTimeout?.cancel();
    super.dispose();
  }
}
