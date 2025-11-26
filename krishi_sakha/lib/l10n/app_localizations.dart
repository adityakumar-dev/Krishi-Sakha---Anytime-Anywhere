import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Krishi Sakha'**
  String get appTitle;

  /// Home screen label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Chat screen label
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// AI Search screen label
  ///
  /// In en, this message translates to:
  /// **'AI Search'**
  String get aiSearch;

  /// Weather screen label
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// Voice Chat screen label
  ///
  /// In en, this message translates to:
  /// **'Voice Chat'**
  String get voiceChat;

  /// Greeting message for user
  ///
  /// In en, this message translates to:
  /// **'Hello, {userName} 👋'**
  String helloUser(String userName);

  /// Morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning!'**
  String get goodMorning;

  /// Afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon!'**
  String get goodAfternoon;

  /// Evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good Evening!'**
  String get goodEvening;

  /// Morning motivation message
  ///
  /// In en, this message translates to:
  /// **'Ready to start your day?'**
  String get readyToStartDay;

  /// Afternoon check-in message
  ///
  /// In en, this message translates to:
  /// **'How\'s your farming going?'**
  String get howsFarmingGoing;

  /// Evening review message
  ///
  /// In en, this message translates to:
  /// **'Time to review today\'s progress'**
  String get timeToReviewProgress;

  /// AI farming section title
  ///
  /// In en, this message translates to:
  /// **'AI-Powered Farming'**
  String get aiPoweredFarming;

  /// AI farming description
  ///
  /// In en, this message translates to:
  /// **'Get intelligent insights for better crops'**
  String get intelligentInsights;

  /// Farm tools section title
  ///
  /// In en, this message translates to:
  /// **'Farm Tools'**
  String get farmTools;

  /// AI search subtitle
  ///
  /// In en, this message translates to:
  /// **'Smart search'**
  String get smartSearch;

  /// Weather subtitle
  ///
  /// In en, this message translates to:
  /// **'Forecasts'**
  String get forecasts;

  /// Local chat title
  ///
  /// In en, this message translates to:
  /// **'Local Chat'**
  String get localChat;

  /// Local chat subtitle
  ///
  /// In en, this message translates to:
  /// **'Offline chat'**
  String get offlineChat;

  /// Voice chat subtitle
  ///
  /// In en, this message translates to:
  /// **'Chat with Voice'**
  String get chatWithVoice;

  /// Statistics section title
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// Active crops stat title
  ///
  /// In en, this message translates to:
  /// **'Active Crops'**
  String get activeCrops;

  /// Crops status
  ///
  /// In en, this message translates to:
  /// **'Growing well'**
  String get growingWell;

  /// AI consultations stat title
  ///
  /// In en, this message translates to:
  /// **'AI Consultations'**
  String get aiConsultations;

  /// Time period indicator
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// Yield improvement stat title
  ///
  /// In en, this message translates to:
  /// **'Yield Improvement'**
  String get yieldImprovement;

  /// Comparison period
  ///
  /// In en, this message translates to:
  /// **'From last season'**
  String get fromLastSeason;

  /// Chat start message
  ///
  /// In en, this message translates to:
  /// **'Start your conversation'**
  String get startConversation;

  /// Chat description
  ///
  /// In en, this message translates to:
  /// **'Ask anything related to farming, crops, weather, and more.'**
  String get askAnythingFarming;

  /// AI thinking indicator
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinking;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type your message…'**
  String get typeYourMessage;

  /// Send button tooltip
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// Image selection confirmation
  ///
  /// In en, this message translates to:
  /// **'Image Selected'**
  String get imageSelected;

  /// No image selection message
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// Dismiss button
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// YouTube videos section title
  ///
  /// In en, this message translates to:
  /// **'YouTube Videos'**
  String get youtubeVideos;

  /// AI Search welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome to AI Search'**
  String get welcomeToAiSearch;

  /// AI Search description
  ///
  /// In en, this message translates to:
  /// **'Get instant answers with sources from across the web. Ask anything about farming, agriculture, or any topic you\'re curious about.'**
  String get aiSearchDescription;

  /// AI Search input placeholder
  ///
  /// In en, this message translates to:
  /// **'Ask anything about farming...'**
  String get askAnythingFarmingDots;

  /// Search suggestions title
  ///
  /// In en, this message translates to:
  /// **'Try searching for:'**
  String get trySearchingFor;

  /// Search suggestion 1
  ///
  /// In en, this message translates to:
  /// **'🌾 Best crops for monsoon season'**
  String get bestCropsMonsoon;

  /// Search suggestion 2
  ///
  /// In en, this message translates to:
  /// **'🚜 Modern farming techniques'**
  String get modernFarmingTechniques;

  /// Search suggestion 3
  ///
  /// In en, this message translates to:
  /// **'🌱 Organic fertilizer methods'**
  String get organicFertilizerMethods;

  /// Search suggestion 4
  ///
  /// In en, this message translates to:
  /// **'💧 Water conservation in agriculture'**
  String get waterConservationAgriculture;

  /// Search suggestion 5
  ///
  /// In en, this message translates to:
  /// **'🐛 Natural pest control solutions'**
  String get naturalPestControl;

  /// Search suggestion 6
  ///
  /// In en, this message translates to:
  /// **'📈 Agricultural market trends'**
  String get agriculturalMarketTrends;

  /// Search error title
  ///
  /// In en, this message translates to:
  /// **'Search Error'**
  String get searchError;

  /// Retry search button
  ///
  /// In en, this message translates to:
  /// **'Retry Search'**
  String get retrySearch;

  /// User search section title
  ///
  /// In en, this message translates to:
  /// **'Your Search'**
  String get yourSearch;

  /// AI answer section title
  ///
  /// In en, this message translates to:
  /// **'AI Answer'**
  String get aiAnswer;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// Try again button
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Speech initialization message
  ///
  /// In en, this message translates to:
  /// **'Initializing speech recognition...'**
  String get initializingSpeechRecognition;

  /// Voice listening indicator
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// Voice instruction message
  ///
  /// In en, this message translates to:
  /// **'Hold and speak to get started.'**
  String get holdAndSpeak;

  /// Local assistants screen title
  ///
  /// In en, this message translates to:
  /// **'Local Assistants'**
  String get localAssistants;

  /// Test APIs button
  ///
  /// In en, this message translates to:
  /// **'Test Apis'**
  String get testApis;

  /// Local chat welcome title
  ///
  /// In en, this message translates to:
  /// **'Ask Me Anything'**
  String get askMeAnything;

  /// Local chat welcome subtitle
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with AI'**
  String get startConversationWithAi;

  /// AI typing indicator
  ///
  /// In en, this message translates to:
  /// **'AI is typing...'**
  String get aiIsTyping;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// AI initialization message
  ///
  /// In en, this message translates to:
  /// **'Initializing AI model...'**
  String get initializingAiModel;

  /// Stop generation tooltip
  ///
  /// In en, this message translates to:
  /// **'Stop generation'**
  String get stopGeneration;

  /// Clear chat tooltip
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get clearChat;

  /// Ready status
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// Loading status
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Response generation status
  ///
  /// In en, this message translates to:
  /// **'Generating response...'**
  String get generatingResponse;

  /// Error status
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorOccurred;

  /// Humidity label
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// Dew point label
  ///
  /// In en, this message translates to:
  /// **'Dew Point'**
  String get dewPoint;

  /// Pressure label
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// Wind speed label
  ///
  /// In en, this message translates to:
  /// **'Wind Speed'**
  String get windSpeed;

  /// UV index label
  ///
  /// In en, this message translates to:
  /// **'UV Index'**
  String get uvIndex;

  /// UV max label
  ///
  /// In en, this message translates to:
  /// **'UV Max'**
  String get uvMax;

  /// Sunrise label
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// Sunset label
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// Rain label
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get rain;

  /// Outdated data indicator
  ///
  /// In en, this message translates to:
  /// **'Outdated'**
  String get outdated;

  /// Welcome message prefix
  ///
  /// In en, this message translates to:
  /// **'Welcome to'**
  String get welcomeTo;

  /// App name
  ///
  /// In en, this message translates to:
  /// **'Krishi Sakha'**
  String get krishiSakha;

  /// Search action
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Delete action
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit action
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Share action
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Copy action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Paste action
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Refresh action
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next action
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Done action
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Close action
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Language switcher button
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// English language label
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hindi language label
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// Language change confirmation message
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// Settings menu
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language settings section
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// App information section
  ///
  /// In en, this message translates to:
  /// **'App Information'**
  String get appInfo;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Developer information
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// Support section
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Feedback option
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Contact us option
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// Settings card title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings card subtitle
  ///
  /// In en, this message translates to:
  /// **'App preferences'**
  String get settingsSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
