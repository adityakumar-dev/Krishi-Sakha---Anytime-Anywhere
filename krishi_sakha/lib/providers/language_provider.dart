import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _localeKey = 'app_locale';

  Locale get currentLocale => _currentLocale;

  // Initialize and load saved locale
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      if (savedLocale != null && savedLocale.isNotEmpty) {
        final parts = savedLocale.split('_');
        final locale = parts.length > 1
            ? Locale(parts[0], parts[1])
            : Locale(parts[0]);
        _currentLocale = locale;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      // Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final localeString = locale.countryCode != null
            ? '${locale.languageCode}_${locale.countryCode}'
            : locale.languageCode;
        await prefs.setString(_localeKey, localeString);
      } catch (e) {
        debugPrint('Error saving locale: $e');
      }
      notifyListeners();
    }
  }

  // Set locale from language code (e.g., 'en-US' -> Locale('en', 'US'))
  Future<void> setLocaleFromCode(String languageCode) async {
    final parts = languageCode.split('-');
    final locale = parts.length > 1
        ? Locale(parts[0], parts[1])
        : Locale(parts[0]);
    await setLocale(locale);
  }

  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isHindi => _currentLocale.languageCode == 'hi';
  bool get isMalayalam => _currentLocale.languageCode == 'ml';

  String get currentLanguageName {
    switch (_currentLocale.languageCode) {
      case 'hi':
        return 'हिंदी';
      case 'ml':
        return 'മലയാളം';
      case 'en':
      default:
        return 'English';
    }
  }

  // Get supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('ml'),
  ];
}
