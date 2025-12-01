import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Status of a translation model
enum ModelDownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  failed,
}

/// Information about a translation language model
class TranslationModelInfo {
  final TranslateLanguage language;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final String languageCode;
  ModelDownloadStatus status;
  double downloadProgress; // 0.0 to 1.0
  String? errorMessage;

  TranslationModelInfo({
    required this.language,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    required this.languageCode,
    this.status = ModelDownloadStatus.notDownloaded,
    this.downloadProgress = 0.0,
    this.errorMessage,
  });

  bool get isDownloaded => status == ModelDownloadStatus.downloaded;
  bool get isDownloading => status == ModelDownloadStatus.downloading;

  TranslationModelInfo copyWith({
    ModelDownloadStatus? status,
    double? downloadProgress,
    String? errorMessage,
  }) {
    return TranslationModelInfo(
      language: language,
      name: name,
      nativeName: nativeName,
      flagEmoji: flagEmoji,
      languageCode: languageCode,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() => 'TranslationModelInfo($name, $status, ${(downloadProgress * 100).toInt()}%)';
}

/// Available Indian languages for translation
class AvailableLanguages {
  static final List<TranslationModelInfo> indianLanguages = [
    TranslationModelInfo(
      language: TranslateLanguage.hindi,
      name: 'Hindi',
      nativeName: 'हिन्दी',
      flagEmoji: '🇮🇳',
      languageCode: 'hi',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.marathi,
      name: 'Marathi',
      nativeName: 'मराठी',
      flagEmoji: '🇮🇳',
      languageCode: 'mr',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.bengali,
      name: 'Bengali',
      nativeName: 'বাংলা',
      flagEmoji: '🇮🇳',
      languageCode: 'bn',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.tamil,
      name: 'Tamil',
      nativeName: 'தமிழ்',
      flagEmoji: '🇮🇳',
      languageCode: 'ta',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.telugu,
      name: 'Telugu',
      nativeName: 'తెలుగు',
      flagEmoji: '🇮🇳',
      languageCode: 'te',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.gujarati,
      name: 'Gujarati',
      nativeName: 'ગુજરાતી',
      flagEmoji: '🇮🇳',
      languageCode: 'gu',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.kannada,
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      flagEmoji: '🇮🇳',
      languageCode: 'kn',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.urdu,
      name: 'Urdu',
      nativeName: 'اردو',
      flagEmoji: '🇮🇳',
      languageCode: 'ur',
    ),
  ];

  static final List<TranslationModelInfo> otherLanguages = [
    TranslationModelInfo(
      language: TranslateLanguage.english,
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇬🇧',
      languageCode: 'en',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.spanish,
      name: 'Spanish',
      nativeName: 'Español',
      flagEmoji: '🇪🇸',
      languageCode: 'es',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.french,
      name: 'French',
      nativeName: 'Français',
      flagEmoji: '🇫🇷',
      languageCode: 'fr',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.german,
      name: 'German',
      nativeName: 'Deutsch',
      flagEmoji: '🇩🇪',
      languageCode: 'de',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.chinese,
      name: 'Chinese',
      nativeName: '中文',
      flagEmoji: '🇨🇳',
      languageCode: 'zh',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.japanese,
      name: 'Japanese',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
      languageCode: 'ja',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.korean,
      name: 'Korean',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
      languageCode: 'ko',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.arabic,
      name: 'Arabic',
      nativeName: 'العربية',
      flagEmoji: '🇸🇦',
      languageCode: 'ar',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.russian,
      name: 'Russian',
      nativeName: 'Русский',
      flagEmoji: '🇷🇺',
      languageCode: 'ru',
    ),
    TranslationModelInfo(
      language: TranslateLanguage.portuguese,
      name: 'Portuguese',
      nativeName: 'Português',
      flagEmoji: '🇵🇹',
      languageCode: 'pt',
    ),
  ];

  static List<TranslationModelInfo> get allLanguages => [...indianLanguages, ...otherLanguages];

  /// Get language info by language code
  static TranslationModelInfo? getByCode(String code) {
    try {
      return allLanguages.firstWhere((l) => l.languageCode == code);
    } catch (_) {
      return null;
    }
  }

  /// Get language info by TranslateLanguage
  static TranslationModelInfo? getByLanguage(TranslateLanguage lang) {
    try {
      return allLanguages.firstWhere((l) => l.language == lang);
    } catch (_) {
      return null;
    }
  }
}
