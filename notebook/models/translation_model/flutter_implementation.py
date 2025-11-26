"""
Flutter/Dart Implementation for Offline-Ready Translation App

STEP 1: Add these dependencies to pubspec.yaml:

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  sqflite: ^2.3.0
  path_provider: ^2.1.0
  provider: ^6.1.0

STEP 2: Create this Dart class for translation management
"""

# ============================================================================
# DART CODE FOR FLUTTER APP (translator_service.dart)
# ============================================================================

dart_code = '''
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:async';

class TranslatorService {
  static const String SERVER_URL = 'http://YOUR_SERVER_IP:5000';
  
  late Database _db;
  bool _isInitialized = false;

  /// Initialize local database and load offline cache
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = '${documentsDirectory.path}/translation_cache.db';
      
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
            CREATE TABLE translations (
              id INTEGER PRIMARY KEY,
              english TEXT NOT NULL,
              language TEXT NOT NULL,
              translation TEXT NOT NULL,
              timestamp INTEGER DEFAULT 0
            )
          ''');
        },
      );
      
      // Load offline phrases from assets
      await _loadOfflineCache();
      _isInitialized = true;
      
      print('✓ Translator initialized with offline cache');
    } catch (e) {
      print('✗ Error initializing translator: $e');
    }
  }

  /// Load offline cache from assets into SQLite
  Future<void> _loadOfflineCache() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/offline_cache.json');
      final jsonData = jsonDecode(jsonString);
      final phrases = jsonData['phrases'] as Map<String, dynamic>;
      
      for (final entry in phrases.entries) {
        final english = entry.key;
        final translations = entry.value as Map<String, dynamic>;
        
        for (final lang in translations.entries) {
          await _db.insert(
            'translations',
            {
              'english': english,
              'language': lang.key,
              'translation': lang.value,
              'timestamp': 0, // Offline cache timestamp = 0
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      print('✓ Loaded ${phrases.length} offline phrases');
    } catch (e) {
      print('✗ Error loading offline cache: $e');
    }
  }

  /// Translate text (cache-first, then server)
  Future<String?> translate(String text, String languageCode) async {
    if (!_isInitialized) await initialize();

    // STEP 1: Check local cache first (instant)
    final cached = await _getFromCache(text, languageCode);
    if (cached != null) {
      print('📱 Cache hit: $text');
      return cached;
    }

    // STEP 2: If not in cache, ask server (when online)
    print('🌐 Fetching from server: $text');
    try {
      final translation = await _fetchFromServer(text, languageCode);
      
      if (translation != null) {
        // STEP 3: Save to cache for future use
        await _saveToCache(text, languageCode, translation);
        return translation;
      }
    } catch (e) {
      print('✗ Server error: $e');
      print('📱 Need internet for new translations');
    }

    return null;
  }

  /// Get translation from local SQLite cache
  Future<String?> _getFromCache(String english, String language) async {
    try {
      final result = await _db.query(
        'translations',
        where: 'english = ? AND language = ?',
        whereArgs: [english, language],
      );
      
      if (result.isNotEmpty) {
        return result.first['translation'] as String?;
      }
    } catch (e) {
      print('✗ Cache query error: $e');
    }
    
    return null;
  }

  /// Get translation from server
  Future<String?> _fetchFromServer(String text, String languageCode) async {
    try {
      final response = await http
          .post(
            Uri.parse('$SERVER_URL/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'language': languageCode,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['translation'] as String;
        }
      }
    } catch (e) {
      print('✗ Server connection error: $e');
    }

    return null;
  }

  /// Save translation to local cache
  Future<void> _saveToCache(
    String english,
    String language,
    String translation,
  ) async {
    try {
      await _db.insert(
        'translations',
        {
          'english': english,
          'language': language,
          'translation': translation,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✓ Cached: $english → $translation');
    } catch (e) {
      print('✗ Cache save error: $e');
    }
  }

  /// Get all cached translations count
  Future<int> getCacheCount() async {
    try {
      final result = await _db.rawQuery('SELECT COUNT(*) as count FROM translations');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('✗ Error getting cache count: $e');
      return 0;
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      await _db.delete('translations');
      print('✓ Cache cleared');
    } catch (e) {
      print('✗ Error clearing cache: $e');
    }
  }

  /// Close database
  Future<void> close() async {
    await _db.close();
  }
}

// ============================================================================
// USAGE IN YOUR FLUTTER WIDGET
// ============================================================================

class TranslatorWidget extends StatefulWidget {
  @override
  State<TranslatorWidget> createState() => _TranslatorWidgetState();
}

class _TranslatorWidgetState extends State<TranslatorWidget> {
  final _translatorService = TranslatorService();
  String _result = '';
  bool _isLoading = false;
  String _selectedLanguage = 'hi'; // Hindi

  @override
  void initState() {
    super.initState();
    _initializeTranslator();
  }

  Future<void> _initializeTranslator() async {
    await _translatorService.initialize();
    final count = await _translatorService.getCacheCount();
    print('Cache ready with $count phrases');
  }

  Future<void> _translate(String text) async {
    setState(() => _isLoading = true);

    final translation = await _translatorService.translate(text, _selectedLanguage);

    setState(() {
      _result = translation ?? 'Translation failed - offline?';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Language selector
        DropdownButton<String>(
          value: _selectedLanguage,
          items: const [
            DropdownMenuItem(value: 'hi', child: Text('🇮🇳 Hindi')),
            DropdownMenuItem(value: 'bn', child: Text('🇧🇩 Bengali')),
            DropdownMenuItem(value: 'ta', child: Text('🇮🇳 Tamil')),
            DropdownMenuItem(value: 'te', child: Text('🇮🇳 Telugu')),
            DropdownMenuItem(value: 'mr', child: Text('🇮🇳 Marathi')),
            DropdownMenuItem(value: 'gu', child: Text('🇮🇳 Gujarati')),
            DropdownMenuItem(value: 'kn', child: Text('🇮🇳 Kannada')),
            DropdownMenuItem(value: 'ml', child: Text('🇮🇳 Malayalam')),
            DropdownMenuItem(value: 'pa', child: Text('🇮🇳 Punjabi')),
            DropdownMenuItem(value: 'ur', child: Text('🇵🇰 Urdu')),
          ],
          onChanged: (value) => setState(() => _selectedLanguage = value!),
        ),
        
        // Input field
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter English text',
            border: OutlineInputBorder(),
          ),
          onSubmitted: _translate,
        ),
        
        // Result
        if (_isLoading) CircularProgressIndicator(),
        if (_result.isNotEmpty)
          Text(
            _result,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
      ],
    );
  }

  @override
  void dispose() {
    _translatorService.close();
    super.dispose();
  }
}
'''

print(dart_code)
print("\n" + "="*80)
print("FLUTTER SETUP COMPLETE")
print("="*80)
