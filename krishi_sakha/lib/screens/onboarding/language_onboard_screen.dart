import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/apis/app_global.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/providers/language_provider.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class LanguageOnboardScreen extends StatefulWidget {
  const LanguageOnboardScreen({super.key});

  @override
  State<LanguageOnboardScreen> createState() => _LanguageOnboardScreenState();
}

class _LanguageOnboardScreenState extends State<LanguageOnboardScreen> {
  String? _selectedLanguage;
  bool _isLoading = false;

  // Language display names mapped to their codes
  final Map<String, String> _languageNames = {
    'en-US': 'English',
    'hi-IN': 'हिंदी (Hindi)',
    'ta-IN': 'தமிழ் (Tamil)',
    'te-IN': 'తెలుగు (Telugu)',
    'kn-IN': 'ಕನ್ನಡ (Kannada)',
    'ml-IN': 'മലയാളം (Malayalam)',
    'bn-IN': 'বাংলা (Bengali)',
    'gu-IN': 'ગુજરાતી (Gujarati)',
    'mr-IN': 'मराठी (Marathi)',
    'pa-IN': 'ਪੰਜਾਬੀ (Punjabi)',
    'ur-IN': 'اردو (Urdu)',
    'or-IN': 'ଓଡ଼ିଆ (Odia)',
    'as-IN': 'অসমীয়া (Assamese)',
    'mai-IN': 'मैथिली (Maithili)',
    'bho-IN': 'भोजपुरी (Bhojpuri)',
    'raj-IN': 'राजस्थानी (Rajasthani)',
    'ne-NP': 'नेपाली (Nepali)',
    'si-LK': 'සිංහල (Sinhala)',
  };

  Future<void> _saveLanguageAndContinue() async {
    if (_selectedLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a language'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final profileProvider = Provider.of<ProfileProvider>(
      context,
      listen: false,
    );
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    
    await profileProvider.setLanguagePreference(_selectedLanguage!);
    
    // Update LanguageProvider for localization (only for en, hi, ml)
    final langCode = _selectedLanguage!.split('-').first;
    if (langCode == 'en' || langCode == 'hi' || langCode == 'ml') {
      await languageProvider.setLocaleFromCode(_selectedLanguage!);
    }

    setState(() {
      _isLoading = false;
    });

    if (profileProvider.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Navigate to location onboard or home based on whether location is set
      if (mounted) {

        if(profileProvider.userProfile?.name == null){
          context.go(AppRoutes.profileOnboard);
        }else{
          profileProvider.userProfile?.preferredWeatherStationId == null? context.go(AppRoutes.locationOnBoard)
            : context.go(AppRoutes.home);
     
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 28),
              ),
              const SizedBox(height: 20),

              // Animation
              Center(
                child: Lottie.asset(
                  'assets/lottie/farmers.json',
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),

              // Title
              const Text(
                'Choose Your Language',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Select your preferred language for voice features',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // Language list
              Expanded(
                child: ListView.builder(
                  itemCount: AppGlobal.supportedLanguages.length,
                  itemBuilder: (context, index) {
                    final langCode = AppGlobal.supportedLanguages[index];
                    final langName = _languageNames[langCode] ?? langCode;
                    final isSelected = _selectedLanguage == langCode;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLanguage = langCode;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green.shade50
                                : Colors.grey.shade100,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Radio indicator
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.green
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),

                              // Language name
                              Expanded(
                                child: Text(
                                  langName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.green.shade900
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLanguageAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
