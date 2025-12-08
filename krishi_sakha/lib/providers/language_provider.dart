import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  void setLocale(Locale locale) {
    if (_currentLocale != locale) {
      _currentLocale = locale;
      notifyListeners();
    }
  }

  // Set locale from language code (e.g., 'en-US' -> Locale('en', 'US'))
  void setLocaleFromCode(String languageCode) {
    final parts = languageCode.split('-');
    final locale = parts.length > 1
        ? Locale(parts[0], parts[1])
        : Locale(parts[0]);
    setLocale(locale);
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
