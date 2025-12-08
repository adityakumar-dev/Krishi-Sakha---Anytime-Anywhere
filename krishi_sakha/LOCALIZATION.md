# Krishi Sakha Localization Guide

## Overview
The app now supports 3 languages:
- **English (en)** - Default
- **Hindi (hi)** - हिंदी
- **Malayalam (ml)** - മലയാളം

## Structure

```
lib/
├── l10n/
│   ├── app_en.arb  # English translations (template)
│   ├── app_hi.arb  # Hindi translations
│   └── app_ml.arb  # Malayalam translations
└── main.dart       # Localization setup

l10n.yaml           # Localization configuration
```

## How to Use Localization in Code

### 1. Import the localization package
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
```

### 2. Use translations in widgets
```dart
// Old way (hardcoded):
Text('My Profile')

// New way (localized):
Text(AppLocalizations.of(context)!.myProfile)
```

### 3. Common examples
```dart
// Button text
ElevatedButton(
  onPressed: () {},
  child: Text(AppLocalizations.of(context)!.save),
)

// AppBar title
AppBar(
  title: Text(AppLocalizations.of(context)!.voiceChat),
)

// Error messages
Text(AppLocalizations.of(context)!.somethingWentWrong)

// Placeholders with parameters
Text(AppLocalizations.of(context)!.deleteModelConfirmation(modelName))
```

## Available Translation Keys

### Common Actions
- `retry`, `cancel`, `save`, `delete`, `close`, `okay`, `yes`, `no`
- `tryAgain`, `refresh`, `back`, `next`, `done`, `skip`, `search`

### Profile
- `profile`, `myProfile`, `editProfile`, `logout`
- `name`, `phone`, `email`, `city`, `state`

### Voice Chat
- `voiceChat`, `listening`, `processing`, `speaking`
- `pressAndHoldToSpeak`, `speakClearlyAndRelease`

### Weather
- `weather`, `weatherForecast`, `temperature`, `humidity`
- `windSpeed`, `pressure`, `sunrise`, `sunset`

### Chat
- `chat`, `newChat`, `startNewChat`, `noConversationsYet`

### Language
- `language`, `selectLanguage`, `saveLanguage`

### Days & Months
- Days: `monday`, `tuesday`, `wednesday`, etc.
- Months: `january`, `february`, `march`, etc.

[See full list in app_en.arb]

## Adding New Translations

### 1. Add to English template (app_en.arb)
```json
{
  "newKey": "New English Text",
  "@newKey": {
    "description": "Description of what this text is for"
  }
}
```

### 2. Add to Hindi (app_hi.arb)
```json
{
  "newKey": "नया हिंदी पाठ"
}
```

### 3. Add to Malayalam (app_ml.arb)
```json
{
  "newKey": "പുതിയ മലയാളം വാചകം"
}
```

### 4. Generate localization files
```bash
flutter gen-l10n
```

This automatically generates the Dart code in `.dart_tool/flutter_gen/gen_l10n/`

## Syncing with User Profile Language

The app syncs language preference with the user's profile:

1. User selects language in Language Screen
2. `ProfileProvider.setLanguagePreference()` saves to backend
3. `LanguageProvider.setLocaleFromCode()` updates UI language
4. All text automatically updates to selected language

## Integration Points

### ProfileProvider
- `prefered_language` field stores user's language choice (e.g., 'en-US', 'hi-IN', 'ml-IN')
- `setLanguagePreference()` API updates backend

### LanguageProvider
- `currentLocale` stores active locale
- `setLocale()` changes app language
- `setLocaleFromCode()` converts 'en-US' → Locale('en', 'US')

### VoiceProvider
- Uses `_userPreferredLanguage` for speech recognition
- Translates responses to user's language

## Testing Localization

1. Change device language to Hindi/Malayalam
2. Or use Language Selection screen
3. All UI text should update automatically

## Missing Translations?

If you see English text in Hindi/Malayalam mode:
1. Check if the key exists in app_hi.arb or app_ml.arb
2. If missing, add translation and run `flutter gen-l10n`
3. Restart the app to see changes

## Best Practices

1. **Always use** `AppLocalizations.of(context)!.keyName` for user-facing text
2. **Never hardcode** user-facing strings in widgets
3. **Add descriptions** in @keyName blocks for context
4. **Keep keys lowercase** with camelCase (e.g., `myProfile`, not `MyProfile`)
5. **Run gen-l10n** after adding new keys
6. **Test all 3 languages** before releasing updates

## Next Steps

1. Replace hardcoded strings throughout the app
2. Add more domain-specific translations (farming terms, etc.)
3. Add more languages if needed (Tamil, Telugu, etc.)
4. Set up translation workflow with translators

---
**Note**: The localization files are auto-generated. Don't edit files in `.dart_tool/flutter_gen/` directly - always edit the ARB files and regenerate.
