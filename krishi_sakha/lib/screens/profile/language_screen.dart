import 'package:flutter/material.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/apis/app_global.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/providers/language_provider.dart';
import 'package:provider/provider.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String? _selectedLanguage;
  bool _isLoading = false;

  final Map<String, Map<String, String>> _languageData = {
    'en-US': {'name': 'English', 'native': 'English'},
    'hi-IN': {'name': 'Hindi', 'native': 'हिन्दी'},
    'ta-IN': {'name': 'Tamil', 'native': 'தமிழ்'},
    'te-IN': {'name': 'Telugu', 'native': 'తెలుగు'},
    'kn-IN': {'name': 'Kannada', 'native': 'ಕನ್ನಡ'},
    'ml-IN': {'name': 'Malayalam', 'native': 'മലയാളം'},
    'bn-IN': {'name': 'Bengali', 'native': 'বাংলা'},
    'gu-IN': {'name': 'Gujarati', 'native': 'ગુજરાતી'},
    'mr-IN': {'name': 'Marathi', 'native': 'मराठी'},
    'pa-IN': {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ'},
    'ur-IN': {'name': 'Urdu', 'native': 'اردو'},
    'or-IN': {'name': 'Odia', 'native': 'ଓଡ଼ିଆ'},
    'as-IN': {'name': 'Assamese', 'native': 'অসমীয়া'},
    'mai-IN': {'name': 'Maithili', 'native': 'मैथिली'},
    'bho-IN': {'name': 'Bhojpuri', 'native': 'भोजपुरी'},
    'raj-IN': {'name': 'Rajasthani', 'native': 'राजस्थानी'},
    'ne-NP': {'name': 'Nepali', 'native': 'नेपाली'},
    'si-LK': {'name': 'Sinhala', 'native': 'සිංහල'},
  };

  @override
  void initState() {
    super.initState();
    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    _selectedLanguage =
        profileProvider.userProfile?.prefered_language ?? 'en-US';
  }

  Future<void> _saveLanguage() async {
    if (_selectedLanguage == null) return;

    setState(() => _isLoading = true);

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    
    await profileProvider.setLanguagePreference(_selectedLanguage!);

    setState(() => _isLoading = false);

    if (mounted) {
      if (profileProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error!),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Update LanguageProvider for localization (only for en, hi, ml)
        final langCode = _selectedLanguage!.split('-').first;
        if (langCode == 'en' || langCode == 'hi' || langCode == 'ml') {
          languageProvider.setLocaleFromCode(_selectedLanguage!);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.languageUpdated),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          l10n.selectLanguage,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: AppGlobal.supportedLanguages.length,
              itemBuilder: (context, index) {
                final langCode = AppGlobal.supportedLanguages[index];
                final langInfo = _languageData[langCode];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedLanguage == langCode
                          ? Colors.green
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    onTap: () {
                      setState(() => _selectedLanguage = langCode);
                    },
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _selectedLanguage == langCode
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        Icons.language,
                        color: _selectedLanguage == langCode
                            ? Colors.green
                            : Colors.grey[600],
                        size: 28,
                      ),
                    ),
                    title: Text(
                      langInfo?['native'] ?? langCode,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _selectedLanguage == langCode
                            ? Colors.green
                            : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      langInfo?['name'] ?? langCode,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    trailing: _selectedLanguage == langCode
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          )
                        : Icon(
                            Icons.circle_outlined,
                            color: Colors.grey[400],
                            size: 28,
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLanguage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          l10n.save,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
