import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:krishi_sakha/services/app_logger.dart';
import 'package:krishi_sakha/apis/api_manager.dart';
import 'package:krishi_sakha/apis/app_global.dart';

// Models
class LanguageOption {
  final String code;
  final String name;

  LanguageOption({required this.code, required this.name});

  factory LanguageOption.fromJson(Map<String, dynamic> json) {
    return LanguageOption(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class TranslationResult {
  final bool success;
  final String original;
  final String translation;
  final String language;
  final String languageName;
  final String? error;

  TranslationResult({
    required this.success,
    required this.original,
    required this.translation,
    required this.language,
    required this.languageName,
    this.error,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      success: json['success'] ?? false,
      original: json['original'] ?? '',
      translation: json['translation'] ?? '',
      language: json['language'] ?? '',
      languageName: json['language_name'] ?? '',
      error: json['error'],
    );
  }

  factory TranslationResult.error(String message) {
    return TranslationResult(
      success: false,
      original: '',
      translation: '',
      language: '',
      languageName: '',
      error: message,
    );
  }
}

// Provider for Translation Service
class TranslationProvider extends ChangeNotifier {
  bool _isTranslating = false;
  TranslationResult? _lastTranslationResult;
  List<LanguageOption> _supportedLanguages = [];
  String _selectedLanguageCode = 'hi'; // Default to Hindi - only supported Indian language

  bool get isTranslating => _isTranslating;
  TranslationResult? get lastTranslationResult => _lastTranslationResult;
  List<LanguageOption> get supportedLanguages => _supportedLanguages;
  String get selectedLanguageCode => _selectedLanguageCode;

  // Get language name from code
  String _getLanguageName(String languageCode) {
    final codeToName = {
      'hi': 'Hindi',
      'bn': 'Bengali',
      'ta': 'Tamil',
      'te': 'Telugu',
      'mr': 'Marathi',
      'gu': 'Gujarati',
      'kn': 'Kannada',
      'ml': 'Malayalam',
      'pa': 'Punjabi',
      'ur': 'Urdu',
    };
    return codeToName[languageCode] ?? 'Unknown';
  }

  // Initialize supported languages
  Future<void> initializeSupportedLanguages() async {
    try {
      AppLogger.info('TranslationProvider: Fetching supported languages');
      final response = await http.get(
        Uri.parse('${ApiManager.baseUrl}${ApiManager.supportedLanguagesUrl}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] && data['languages'] != null) {
          _supportedLanguages = (data['languages'] as List)
              .map((lang) => LanguageOption.fromJson(lang))
              .toList();
          AppLogger.info('TranslationProvider: Loaded ${_supportedLanguages.length} languages');
        }
      }
    } catch (e) {
      AppLogger.error('TranslationProvider: Error fetching languages: $e');
    }
  }

  // Set selected language from settings
  void setSelectedLanguage(String languageCode) {
    _selectedLanguageCode = languageCode;
    AppLogger.debug('TranslationProvider: Language changed to $_selectedLanguageCode');
    notifyListeners();
  }

  // Remove markdown formatting from text
  String _stripMarkdown(String text) {
    // Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    // Remove inline code
    text = text.replaceAll(RegExp(r'`([^`]*)`'), r'$1');
    // Remove bold/italic
    text = text.replaceAll(RegExp(r'(\*\*|__)(.*?)\1'), r'$2');
    text = text.replaceAll(RegExp(r'(\*|_)(.*?)\1'), r'$2');
    // Remove headings
    text = text.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    // Remove lists
    text = text.replaceAll(RegExp(r'^[-*+]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '');
    // Remove links/images
    text = text.replaceAll(RegExp(r'!\[[^\]]*\]\([^\)]*\)'), '');
    text = text.replaceAll(RegExp(r'\[[^\]]*\]\([^\)]*\)'), '');
    // Remove blockquotes
    text = text.replaceAll(RegExp(r'^>\s*', multiLine: true), '');
    // Remove horizontal rules
    text = text.replaceAll(RegExp(r'^---$', multiLine: true), '');
    // Remove extra whitespace
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text.trim();
  }

  // Translate single text
  Future<TranslationResult> translateText(
    String text, {
    String? targetLanguage,
  }) async {
    // Always default to Hindi ('hi') - ignore app localization
    final language = targetLanguage ?? 'hi';
    
    final cleanText = _stripMarkdown(text);
    if (cleanText.isEmpty) {
      return TranslationResult.error('Text cannot be empty');
    }
    
    // Validate language is supported
    final supportedLangs = ['hi', 'bn', 'ta', 'te', 'mr', 'gu', 'kn', 'ml', 'pa', 'ur'];
    if (!supportedLangs.contains(language)) {
      final error = 'Language "$language" is not supported. Supported: ${supportedLangs.join(', ')}';
      AppLogger.error('TranslationProvider: $error');
      _lastTranslationResult = TranslationResult.error(error);
      return _lastTranslationResult!;
    }

    _isTranslating = true;
    notifyListeners();

    try {
      AppLogger.info('TranslationProvider: Translating to $language');
      final body = jsonEncode({
        'text': cleanText,
        'language': language,
      });
      AppLogger.info('TranslationProvider: body : ${body}');
     
      final response = await http.post(
        Uri.parse('${ApiManager.baseUrl}${ApiManager.translateUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 30));

      _isTranslating = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Parse the response from backend
        // Backend returns: translation, original, language, language_name
        final translatedText = data['translation'] ?? '';
        final originalText = data['original'] ?? cleanText;
        final langName = data['language_name'] ?? _getLanguageName(language);
        
        _lastTranslationResult = TranslationResult(
          success: true,
          original: originalText,
          translation: translatedText,
          language: language,
          languageName: langName,
        );
        AppLogger.info(
          'TranslationProvider: Translation successful - Original: "$originalText" -> Translation: "$translatedText"',
        );
        notifyListeners();
        return _lastTranslationResult!;
      } else {
        final error = 'Translation failed with status ${response.statusCode}';
        AppLogger.error('TranslationProvider: $error - Response: ${response.body}');
        _lastTranslationResult = TranslationResult.error(error);
        notifyListeners();
        return _lastTranslationResult!;
      }
    } catch (e) {
      _isTranslating = false;
      final error = 'Translation error: $e';
      _lastTranslationResult = TranslationResult.error(error);
      AppLogger.error('TranslationProvider: $error');
      notifyListeners();
      return _lastTranslationResult!;
    }
  }

  // Batch translate multiple texts
  Future<List<TranslationResult>> batchTranslateText(
    List<String> texts, {
    String? targetLanguage,
  }) async {
    // Always default to Hindi ('hi') - ignore app localization
    final language = targetLanguage ?? 'hi';
    
    if (texts.isEmpty) {
      return [TranslationResult.error('Texts list cannot be empty')];
    }

    // Strip markdown from all texts
    final cleanTexts = texts.map((text) => _stripMarkdown(text)).toList();
    
    // Validate language is supported
    final supportedLangs = ['hi', 'bn', 'ta', 'te', 'mr', 'gu', 'kn', 'ml', 'pa', 'ur'];
    if (!supportedLangs.contains(language)) {
      final error = 'Language "$language" is not supported. Supported: ${supportedLangs.join(', ')}';
      AppLogger.error('TranslationProvider: $error');
      return [TranslationResult.error(error)];
    }

    _isTranslating = true;
    notifyListeners();

    try {
      AppLogger.info('TranslationProvider: Batch translating ${cleanTexts.length} items to $language');

      final response = await http.post(
        Uri.parse('${ApiManager.baseUrl}${ApiManager.batchTranslateUrl}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'texts': cleanTexts,
          'language': language,
        }),
      ).timeout(const Duration(seconds: 30));

      _isTranslating = false;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Backend returns: results with original and translation fields
        if (data['results'] != null) {
          final results = (data['results'] as List)
              .map((result) {
                final original = result is String ? result : result['original'] ?? '';
                final translation = result is String ? result : result['translation'] ?? '';
                return TranslationResult(
                  success: true,
                  original: original,
                  translation: translation,
                  language: language,
                  languageName: _getLanguageName(language),
                );
              })
              .toList();
          AppLogger.info('TranslationProvider: Batch translation completed');
          notifyListeners();
          return results;
        }
      }
      final error = 'Batch translation failed';
      AppLogger.error('TranslationProvider: $error - Response: ${response.body}');
      notifyListeners();
      return [TranslationResult.error(error)];
    } catch (e) {
      _isTranslating = false;
      final error = 'Batch translation error: $e';
      AppLogger.error('TranslationProvider: $error');
      notifyListeners();
      return [TranslationResult.error(error)];
    }
  }

  // Show translation dialog globally
  Future<void> showTranslationDialog(TranslationResult result) async {
    try {
      final context = AppGlobal.navigatorKey.currentContext;
      AppLogger.info("TranslationProvider: Showing translation dialog with result for ${result.languageName} result : ${result.translation}");
      if (context == null || !context.mounted) {
        AppLogger.error('TranslationProvider: Invalid context for dialog');
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.translate, color: Colors.green),
                const SizedBox(width: 12),
                const Text(
                  'Translation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Original Text Section
                  Container(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text(
                              'Original (English):',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.maxFinite,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            result.original.isNotEmpty
                                ? result.original
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_downward,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                  ),

                  // Translated Text Section
                  Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Translation (${result.languageName}):',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.maxFinite,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            result.translation.isNotEmpty
                                ? result.translation
                                : 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                icon: const Icon(Icons.close),
                label: const Text('Close'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  // Show language selection dialog after closing translation dialog
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showLanguageSelectionDialog();
                  });
                },
                icon: const Icon(Icons.language),
                label: const Text('Change Language'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      AppLogger.error('TranslationProvider: Error showing dialog: $e');
    }
  }

  // Show language selection dialog
  Future<void> _showLanguageSelectionDialog() async {
    try {
      final context = AppGlobal.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        AppLogger.error('TranslationProvider: Invalid context for language dialog');
        return;
      }

      String selectedLanguage = _selectedLanguageCode;

      final languages = [
        {'code': 'hi', 'name': 'हिंदी (Hindi)'},
        {'code': 'bn', 'name': 'বাংলা (Bengali)'},
        {'code': 'ta', 'name': 'தமிழ் (Tamil)'},
        {'code': 'te', 'name': 'తెలుగు (Telugu)'},
        {'code': 'mr', 'name': 'मराठी (Marathi)'},
        {'code': 'gu', 'name': 'ગુજરાતી (Gujarati)'},
        {'code': 'kn', 'name': 'ಕನ್ನಡ (Kannada)'},
        {'code': 'ml', 'name': 'മലയാളം (Malayalam)'},
        {'code': 'pa', 'name': 'ਪੰਜਾਬੀ (Punjabi)'},
        {'code': 'ur', 'name': 'اردو (Urdu)'},
      ];

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.language, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Language',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...languages.map((lang) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: selectedLanguage == lang['code']
                                ? Colors.blue[50]
                                : Colors.transparent,
                            border: Border.all(
                              color: selectedLanguage == lang['code']
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: selectedLanguage == lang['code'] ? 2 : 1,
                            ),
                          ),
                          child: RadioListTile<String>(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              lang['name'] ?? '',
                              style: TextStyle(
                                fontWeight: selectedLanguage == lang['code']
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            value: lang['code'] ?? '',
                            groupValue: selectedLanguage,
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  selectedLanguage = value;
                                });
                              }
                            },
                            activeColor: Colors.blue,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      // Show confirmation toast
                      _showToast(
                        'Language changed to ${_getLanguageName(selectedLanguage)} (for this process)',
                      );
                      AppLogger.info(
                        'TranslationProvider: Language changed to $selectedLanguage for current process only',
                      );
                      // Re-translate with the selected language for current process
                      if (_lastTranslationResult != null && _lastTranslationResult!.original.isNotEmpty) {

                        await Future.delayed(const Duration(milliseconds: 300));
                        translateAndShowDialog(_lastTranslationResult!.original, targetLanguage: selectedLanguage);
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Okay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      AppLogger.error('TranslationProvider: Error showing language dialog: $e');
    }
  }

  // Translate and show dialog
  Future<void> translateAndShowDialog(String text, {String? targetLanguage}) async {
    try {
      // Always default to Hindi ('hi') - ignore app localization
      final language = targetLanguage ?? 'hi';
      
      // Show initial toast
      _showToast('Converting to your preferred language... ${_getLanguageName(language)}');

      // Perform translation
      final result = await translateText(text, targetLanguage: language);

      if (result.success) {
        // Show translation dialog
        await showTranslationDialog(result);
      } else {
        _showToast('Translation failed: ${result.error}', isError: true);
      }
    } catch (e) {
      AppLogger.error('TranslationProvider: Error in translateAndShowDialog: $e');
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
            content: Text(message),
            duration: const Duration(seconds: 1),
            backgroundColor: isError ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        AppLogger.debug('TranslationProvider: Toast shown - $message');
      }
    } catch (e) {
      AppLogger.error('TranslationProvider: Error showing toast: $e');
    }
  }
}
