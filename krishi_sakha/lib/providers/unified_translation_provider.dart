import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:krishi_sakha/services/OpusOnnxTranslater.dart';
import 'package:krishi_sakha/apis/app_global.dart';
import 'package:krishi_sakha/utils/theme/colors.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';

// Translation result model
class TranslationResult {
  final bool success;
  final String translation;
  final String language;
  final String languageName;
  final String? error;
  final bool usedOffline;

  TranslationResult({
    required this.success,
    required this.translation,
    required this.language,
    required this.languageName,
    this.error,
    this.usedOffline = false,
  });

  factory TranslationResult.error(String message) {
    return TranslationResult(
      success: false,
      translation: '',
      language: '',
      languageName: '',
      error: message,
    );
  }
}

// Unified Translation Provider - combines online and offline translation
class UnifiedTranslationProvider extends ChangeNotifier {
  bool _isTranslating = false;
  TranslationResult? _lastTranslationResult;
  String _selectedLanguageCode = 'hi'; // Default to Hindi

  // Offline translation service
  OpusOnnxTranslator? _offlineTranslator;
  bool _isOfflineInitialized = false;

  bool get isTranslating => _isTranslating;
  TranslationResult? get lastTranslationResult => _lastTranslationResult;
  String get selectedLanguageCode => _selectedLanguageCode;
  bool get isOfflineAvailable => _isOfflineInitialized;

  // Supported languages with offline model availability
  final Map<String, Map<String, dynamic>> _supportedLanguages = {
    'hi': {'name': 'हिंदी (Hindi)', 'hasOffline': false},
    'ml': {
      'name': 'മലയാളം (Malayalam)',
      'hasOffline': true,
    }, // Offline model available
    'bn': {'name': 'বাংলা (Bengali)', 'hasOffline': false},
    'ta': {'name': 'தமிழ் (Tamil)', 'hasOffline': false},
    'te': {'name': 'తెలుగు (Telugu)', 'hasOffline': false},
    'mr': {'name': 'मराठी (Marathi)', 'hasOffline': false},
    'gu': {'name': 'ગુજરાતી (Gujarati)', 'hasOffline': false},
    'kn': {'name': 'ಕನ್ನಡ (Kannada)', 'hasOffline': false},
    'pa': {'name': 'ਪੰਜਾਬੀ (Punjabi)', 'hasOffline': false},
    'ur': {'name': 'اردو (Urdu)', 'hasOffline': false},
  };

  // Get language name from code
  String getLanguageName(String languageCode) {
    return _supportedLanguages[languageCode]?['name'] ?? 'Unknown';
  }

  // Check if offline model is available for language
  bool hasOfflineModel(String languageCode) {
    return _supportedLanguages[languageCode]?['hasOffline'] ?? false;
  }

  // Initialize offline translator (for Malayalam)
  Future<void> initializeOfflineTranslation() async {
    if (_isOfflineInitialized) return;

    try {
      AppLogger.info(
        'UnifiedTranslationProvider: Initializing offline translator...',
      );
      _offlineTranslator = OpusOnnxTranslator();
      await _offlineTranslator!.init();
      _isOfflineInitialized = true;
      AppLogger.info('UnifiedTranslationProvider: Offline translator ready');
    } catch (e) {
      AppLogger.error('UnifiedTranslationProvider: Offline init failed: $e');
      _isOfflineInitialized = false;
    }
  }

  // Set selected language
  void setSelectedLanguage(String languageCode) {
    _selectedLanguageCode = languageCode;
    AppLogger.debug(
      'UnifiedTranslationProvider: Language changed to $_selectedLanguageCode',
    );
    notifyListeners();
  }

  // Remove markdown formatting from text
  String _stripMarkdown(String text) {
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    text = text.replaceAll(RegExp(r'`([^`]*)`'), r'$1');
    text = text.replaceAll(RegExp(r'(\*\*|__)(.*?)\1'), r'$2');
    text = text.replaceAll(RegExp(r'(\*|_)(.*?)\1'), r'$2');
    text = text.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^\)]*\)'), '');
    text = text.replaceAll(RegExp(r'\[[^\]]*\]\([^\)]*\)'), '');
    text = text.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^---$', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  // Main translate method - tries online first, falls back to offline
  Future<TranslationResult> translateText(
    String text, {
    String? targetLanguage,
    bool addDelay = false, // Add delay between translations to prevent crashes
  }) async {
    final language = targetLanguage ?? _selectedLanguageCode;
    final cleanText = _stripMarkdown(text);

    if (cleanText.isEmpty) {
      return TranslationResult.error('Text cannot be empty');
    }

    if (!_supportedLanguages.containsKey(language)) {
      return TranslationResult.error('Language "$language" is not supported');
    }

    _isTranslating = true;
    notifyListeners();

    // Add delay if requested to prevent overwhelming the system
    if (addDelay) {
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      // Try online translation first (faster and more reliable)
      AppLogger.info(
        'UnifiedTranslationProvider: Attempting online translation to $language',
      );

      try {
        final onlineResult = await _translateViaGoogle(cleanText, language);
        _isTranslating = false;
        _lastTranslationResult = onlineResult;
        notifyListeners();
        return _lastTranslationResult!;
      } catch (onlineError) {
        AppLogger.error(
          'UnifiedTranslationProvider: Online failed: $onlineError',
        );

        // Check if it's a network error
        final isNetworkError =
            onlineError.toString().contains('SocketException') ||
            onlineError.toString().contains('TimeoutException') ||
            onlineError.toString().contains('Failed host lookup');

        // If network error and offline available, try offline
        if (isNetworkError && hasOfflineModel(language)) {
          AppLogger.info(
            'UnifiedTranslationProvider: Network error, trying offline translation',
          );

          if (!_isOfflineInitialized) {
            await initializeOfflineTranslation();
          }

          if (_isOfflineInitialized && _offlineTranslator != null) {
            try {
              final translatedText = await _offlineTranslator!.translate(
                cleanText,
              );
              _isTranslating = false;

              _lastTranslationResult = TranslationResult(
                success: true,
                translation: translatedText,
                language: language,
                languageName: getLanguageName(language),
                usedOffline: true,
              );

              AppLogger.info(
                'UnifiedTranslationProvider: Offline translation successful',
              );
              notifyListeners();
              return _lastTranslationResult!;
            } catch (offlineError) {
              AppLogger.error(
                'UnifiedTranslationProvider: Offline also failed: $offlineError',
              );
              throw Exception('Both online and offline translation failed');
            }
          } else {
            throw Exception('Network error and offline model not initialized');
          }
        } else {
          // Not a network error or no offline model available
          throw onlineError;
        }
      }
    } catch (e) {
      _isTranslating = false;

      // Check if it's a network error
      final isNetworkError =
          e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Failed host lookup');

      String errorMessage;
      if (isNetworkError && hasOfflineModel(language)) {
        errorMessage =
            'Translation failed: Please download offline ${getLanguageName(language)} language model';
      } else if (isNetworkError) {
        errorMessage =
            'Translation failed: No internet connection and no offline model available for ${getLanguageName(language)}';
      } else {
        errorMessage = 'Translation error: $e';
      }

      _lastTranslationResult = TranslationResult.error(errorMessage);
      AppLogger.error('UnifiedTranslationProvider: $errorMessage');
      notifyListeners();
      return _lastTranslationResult!;
    }
  }

  // Google Translate API helper
  Future<TranslationResult> _translateViaGoogle(
    String text,
    String targetLang,
  ) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=en&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Translation request timeout'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String translatedText = '';

        if (data != null && data[0] != null) {
          for (var item in data[0]) {
            if (item[0] != null) {
              translatedText += item[0];
            }
          }
        }

        if (translatedText.isNotEmpty) {
          AppLogger.info(
            'UnifiedTranslationProvider: Online translation successful',
          );
          return TranslationResult(
            success: true,
            translation: translatedText,
            language: targetLang,
            languageName: getLanguageName(targetLang),
            usedOffline: false,
          );
        }
      }

      throw Exception('Translation failed with status ${response.statusCode}');
    } catch (e) {
      throw Exception('Google Translate error: $e');
    }
  }

  // Show beautiful translation dialog
  Future<void> showTranslationDialog(TranslationResult result) async {
    try {
      final context = AppGlobal.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        AppLogger.error(
          'UnifiedTranslationProvider: Invalid context for dialog',
        );
        return;
      }

      final l10n = AppLocalizations.of(context);

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF7F5E8), Color(0xFFE8F5E9)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.translate,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.translation ?? 'Translation',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.primaryBlack,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    result.usedOffline
                                        ? Icons.offline_bolt
                                        : Icons.cloud_done,
                                    size: 14,
                                    color: result.usedOffline
                                        ? Colors.orange
                                        : Colors.blue,
                                  ),
                                  // const SizedBox(width: 4),
                                  // Text(
                                  //   result.usedOffline ? 'Offline' : 'Online',
                                  //   style: TextStyle(
                                  //     fontSize: 12,
                                  //     color: result.usedOffline
                                  //         ? Colors.orange
                                  //         : Colors.blue,
                                  //     fontWeight: FontWeight.w600,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          icon: const Icon(Icons.close),
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Language badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.language,
                                  size: 16,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  result.languageName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Translated text
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primaryGreen.withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(
                                    0.1,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              result.translation.isNotEmpty
                                  ? result.translation
                                  : 'N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryBlack,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer with action buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                _showLanguageSelectionDialog();
                              },
                            );
                          },
                          icon: const Icon(Icons.swap_horiz, size: 18),
                          label: Text(l10n?.translateTo ?? 'Change Language'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryGreen,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          },
                          // icon: const Icon(Icons.check, size: 18),
                          label: Text(l10n?.close ?? 'Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.error('UnifiedTranslationProvider: Error showing dialog: $e');
    }
  }

  // Show language selection dialog
  Future<void> _showLanguageSelectionDialog() async {
    try {
      final context = AppGlobal.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        AppLogger.error(
          'UnifiedTranslationProvider: Invalid context for language dialog',
        );
        return;
      }

      final l10n = AppLocalizations.of(context);
      String selectedLanguage = _selectedLanguageCode;

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                    maxHeight: 600,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F5E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.language,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                l10n?.translateTo ?? 'Select Language',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: AppColors.primaryBlack,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              },
                              icon: const Icon(Icons.close),
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      // Language list
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _supportedLanguages.entries.map((entry) {
                              final code = entry.key;
                              final info = entry.value;
                              final isSelected = selectedLanguage == code;
                              final hasOffline = info['hasOffline'] as bool;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected
                                      ? AppColors.primaryGreen.withOpacity(0.1)
                                      : Colors.white,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : Colors.grey.withOpacity(0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: RadioListTile<String>(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          info['name'] as String,
                                          style: TextStyle(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 15,
                                            color: AppColors.primaryBlack,
                                          ),
                                        ),
                                      ),
                                      if (hasOffline)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(
                                                Icons.offline_bolt,
                                                size: 12,
                                                color: Colors.orange,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Offline',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.orange,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  value: code,
                                  groupValue: selectedLanguage,
                                  onChanged: (String? value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedLanguage = value;
                                      });
                                    }
                                  },
                                  activeColor: AppColors.primaryGreen,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      // Footer buttons
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                              },
                              child: Text(l10n?.cancel ?? 'Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }

                                _showToast(
                                  'Language changed to ${getLanguageName(selectedLanguage)}',
                                );

                                // Re-translate with selected language
                                if (_lastTranslationResult != null &&
                                    _lastTranslationResult!
                                        .translation
                                        .isNotEmpty) {
                                  await Future.delayed(
                                    const Duration(milliseconds: 300),
                                  );
                                  // Get original English text from voice provider or store it separately
                                  // For now, we'll translate the last result again
                                  translateAndShowDialog(
                                    _lastTranslationResult!.translation,
                                    targetLanguage: selectedLanguage,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Text(l10n?.okay ?? 'Okay'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      AppLogger.error(
        'UnifiedTranslationProvider: Error showing language dialog: $e',
      );
    }
  }

  // Translate and show dialog
  Future<void> translateAndShowDialog(
    String text, {
    String? targetLanguage,
  }) async {
    try {
      final language = targetLanguage ?? _selectedLanguageCode;

      _showToast('Translating to ${getLanguageName(language)}...');

      final result = await translateText(text, targetLanguage: language);

      if (result.success) {
        await showTranslationDialog(result);
      } else {
        _showToast(result.error ?? 'Translation failed', isError: true);
      }
    } catch (e) {
      AppLogger.error(
        'UnifiedTranslationProvider: Error in translateAndShowDialog: $e',
      );
      _showToast('Error during translation', isError: true);
    }
  }

  // Show toast notification
  void _showToast(String message, {bool isError = false}) {
    try {
      final context = AppGlobal.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(message, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
            duration: Duration(seconds: isError ? 3 : 2),
            backgroundColor: isError
                ? Colors.red.shade600
                : AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        AppLogger.debug('UnifiedTranslationProvider: Toast shown - $message');
      }
    } catch (e) {
      AppLogger.error('UnifiedTranslationProvider: Error showing toast: $e');
    }
  }
}
