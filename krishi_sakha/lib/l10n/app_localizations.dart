import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ml.dart';

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
    Locale('ml'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Krishi Sakha'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @okay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get okay;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @noProfileFound.
  ///
  /// In en, this message translates to:
  /// **'No profile found'**
  String get noProfileFound;

  /// No description provided for @reloadProfile.
  ///
  /// In en, this message translates to:
  /// **'Reload Profile'**
  String get reloadProfile;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @yourChoice.
  ///
  /// In en, this message translates to:
  /// **'Your Choice'**
  String get yourChoice;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @memberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSince;

  /// No description provided for @translationModels.
  ///
  /// In en, this message translates to:
  /// **'Translation Models'**
  String get translationModels;

  /// No description provided for @downloadLanguages.
  ///
  /// In en, this message translates to:
  /// **'Download languages for offline translation'**
  String get downloadLanguages;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @voiceChat.
  ///
  /// In en, this message translates to:
  /// **'Voice Chat'**
  String get voiceChat;

  /// No description provided for @stopVoiceChat.
  ///
  /// In en, this message translates to:
  /// **'Stop voice chat?'**
  String get stopVoiceChat;

  /// No description provided for @cancelOperation.
  ///
  /// In en, this message translates to:
  /// **'This will cancel the current operation.'**
  String get cancelOperation;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @startListening.
  ///
  /// In en, this message translates to:
  /// **'Start Listening'**
  String get startListening;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @speaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get speaking;

  /// No description provided for @pressAndHoldToSpeak.
  ///
  /// In en, this message translates to:
  /// **'👇 Press and hold the button to start listening'**
  String get pressAndHoldToSpeak;

  /// No description provided for @speakClearlyAndRelease.
  ///
  /// In en, this message translates to:
  /// **'🎤 Speak clearly and release to send'**
  String get speakClearlyAndRelease;

  /// No description provided for @processingYourRequest.
  ///
  /// In en, this message translates to:
  /// **'⏳ Processing your request...'**
  String get processingYourRequest;

  /// No description provided for @initializingSpeechRecognition.
  ///
  /// In en, this message translates to:
  /// **'Initializing speech recognition...'**
  String get initializingSpeechRecognition;

  /// No description provided for @holdAndSpeakToStart.
  ///
  /// In en, this message translates to:
  /// **'Hold and speak to start'**
  String get holdAndSpeakToStart;

  /// No description provided for @response.
  ///
  /// In en, this message translates to:
  /// **'Response:'**
  String get response;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @weatherForecast.
  ///
  /// In en, this message translates to:
  /// **'Weather Forecast'**
  String get weatherForecast;

  /// No description provided for @noWeatherData.
  ///
  /// In en, this message translates to:
  /// **'No Weather Data'**
  String get noWeatherData;

  /// No description provided for @addCityToViewWeather.
  ///
  /// In en, this message translates to:
  /// **'Add a city to view weather information'**
  String get addCityToViewWeather;

  /// No description provided for @addCity.
  ///
  /// In en, this message translates to:
  /// **'Add City'**
  String get addCity;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get somethingWentWrong;

  /// No description provided for @imdWeather.
  ///
  /// In en, this message translates to:
  /// **'IMD Weather'**
  String get imdWeather;

  /// No description provided for @addStation.
  ///
  /// In en, this message translates to:
  /// **'Add Station'**
  String get addStation;

  /// No description provided for @noWeatherStationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No weather stations available'**
  String get noWeatherStationsAvailable;

  /// No description provided for @selectYourStation.
  ///
  /// In en, this message translates to:
  /// **'Select Your Station'**
  String get selectYourStation;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @startNewChat.
  ///
  /// In en, this message translates to:
  /// **'Start New Chat'**
  String get startNewChat;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @startNewConversationToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation to get started'**
  String get startNewConversationToGetStarted;

  /// No description provided for @untitledChat.
  ///
  /// In en, this message translates to:
  /// **'Untitled Chat'**
  String get untitledChat;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated successfully'**
  String get languageUpdated;

  /// No description provided for @languageUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Language updated successfully'**
  String get languageUpdatedSuccessfully;

  /// No description provided for @saveLanguage.
  ///
  /// In en, this message translates to:
  /// **'Save Language'**
  String get saveLanguage;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @selectYourState.
  ///
  /// In en, this message translates to:
  /// **'🗺️ Select Your State'**
  String get selectYourState;

  /// No description provided for @orChooseYourState.
  ///
  /// In en, this message translates to:
  /// **'OR CHOOSE YOUR STATE'**
  String get orChooseYourState;

  /// No description provided for @detectStateAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Detect State Automatically'**
  String get detectStateAutomatically;

  /// No description provided for @detecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get detecting;

  /// No description provided for @selectState.
  ///
  /// In en, this message translates to:
  /// **'Select State'**
  String get selectState;

  /// No description provided for @models.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get models;

  /// No description provided for @localModels.
  ///
  /// In en, this message translates to:
  /// **'Local Models'**
  String get localModels;

  /// No description provided for @localAssistants.
  ///
  /// In en, this message translates to:
  /// **'Local Assistants'**
  String get localAssistants;

  /// No description provided for @setActive.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get setActive;

  /// No description provided for @deleteModel.
  ///
  /// In en, this message translates to:
  /// **'Delete Model'**
  String get deleteModel;

  /// No description provided for @deleteModelConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{modelName}\"?'**
  String deleteModelConfirmation(String modelName);

  /// No description provided for @modelDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Model deleted successfully'**
  String get modelDeletedSuccessfully;

  /// No description provided for @failedToDeleteModel.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete model'**
  String get failedToDeleteModel;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone'**
  String get enterYourPhone;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @enterCityName.
  ///
  /// In en, this message translates to:
  /// **'Enter city name'**
  String get enterCityName;

  /// No description provided for @enterStateName.
  ///
  /// In en, this message translates to:
  /// **'Enter state name'**
  String get enterStateName;

  /// No description provided for @search_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search_placeholder;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get noResults;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found for your search'**
  String get noResultsFound;

  /// No description provided for @failedToLoadMap.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Map'**
  String get failedToLoadMap;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @windSpeed.
  ///
  /// In en, this message translates to:
  /// **'Wind Speed'**
  String get windSpeed;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels Like'**
  String get feelsLike;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @cloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get cloudy;

  /// No description provided for @rainy.
  ///
  /// In en, this message translates to:
  /// **'Rainy'**
  String get rainy;

  /// No description provided for @stormy.
  ///
  /// In en, this message translates to:
  /// **'Stormy'**
  String get stormy;

  /// No description provided for @snowy.
  ///
  /// In en, this message translates to:
  /// **'Snowy'**
  String get snowy;

  /// No description provided for @foggy.
  ///
  /// In en, this message translates to:
  /// **'Foggy'**
  String get foggy;

  /// No description provided for @crop.
  ///
  /// In en, this message translates to:
  /// **'Crop'**
  String get crop;

  /// No description provided for @crops.
  ///
  /// In en, this message translates to:
  /// **'Crops'**
  String get crops;

  /// No description provided for @disease.
  ///
  /// In en, this message translates to:
  /// **'Disease'**
  String get disease;

  /// No description provided for @diseases.
  ///
  /// In en, this message translates to:
  /// **'Diseases'**
  String get diseases;

  /// No description provided for @scheme.
  ///
  /// In en, this message translates to:
  /// **'Scheme'**
  String get scheme;

  /// No description provided for @schemes.
  ///
  /// In en, this message translates to:
  /// **'Schemes'**
  String get schemes;

  /// No description provided for @market.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get market;

  /// No description provided for @mandi.
  ///
  /// In en, this message translates to:
  /// **'Mandi'**
  String get mandi;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @prices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get prices;

  /// No description provided for @satellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get satellite;

  /// No description provided for @satelliteView.
  ///
  /// In en, this message translates to:
  /// **'Satellite View'**
  String get satelliteView;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @mapView.
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @rank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get rank;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploads.
  ///
  /// In en, this message translates to:
  /// **'Uploads'**
  String get uploads;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permissionRequired;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required'**
  String get locationPermissionRequired;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission is required'**
  String get cameraPermissionRequired;

  /// No description provided for @storagePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required'**
  String get storagePermissionRequired;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required'**
  String get microphonePermissionRequired;

  /// No description provided for @smartFarmingBegins.
  ///
  /// In en, this message translates to:
  /// **'Smart farming begins today!'**
  String get smartFarmingBegins;

  /// No description provided for @communityPosts.
  ///
  /// In en, this message translates to:
  /// **'Community Posts'**
  String get communityPosts;

  /// No description provided for @expertPosts.
  ///
  /// In en, this message translates to:
  /// **'Expert Posts'**
  String get expertPosts;

  /// No description provided for @expertAdvice.
  ///
  /// In en, this message translates to:
  /// **'Expert Advice'**
  String get expertAdvice;

  /// No description provided for @successStories.
  ///
  /// In en, this message translates to:
  /// **'Success Stories'**
  String get successStories;

  /// No description provided for @bulletins.
  ///
  /// In en, this message translates to:
  /// **'Bulletins'**
  String get bulletins;

  /// No description provided for @successStory.
  ///
  /// In en, this message translates to:
  /// **'Success Story'**
  String get successStory;

  /// No description provided for @bulletin.
  ///
  /// In en, this message translates to:
  /// **'Bulletin'**
  String get bulletin;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @yourCity.
  ///
  /// In en, this message translates to:
  /// **'Your City'**
  String get yourCity;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @noPostsFound.
  ///
  /// In en, this message translates to:
  /// **'No posts found'**
  String get noPostsFound;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorOccurred;

  /// No description provided for @postSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Post submitted for verification'**
  String get postSubmitted;

  /// No description provided for @pleaseAddContent.
  ///
  /// In en, this message translates to:
  /// **'Please add a description or an image'**
  String get pleaseAddContent;

  /// No description provided for @tapToAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a photo'**
  String get tapToAddPhoto;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @postYourThought.
  ///
  /// In en, this message translates to:
  /// **'Post your thought...'**
  String get postYourThought;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first to comment!'**
  String get noCommentsYet;

  /// No description provided for @savedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get savedPosts;

  /// No description provided for @postRemoved.
  ///
  /// In en, this message translates to:
  /// **'Post removed from saved'**
  String get postRemoved;

  /// No description provided for @createNewPost.
  ///
  /// In en, this message translates to:
  /// **'Create New Post'**
  String get createNewPost;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get locationPermission;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission and location services are required for weather reports. Please enable them to continue.'**
  String get locationPermissionMessage;

  /// No description provided for @grantLocationPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantLocationPermission;

  /// No description provided for @noWeatherDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Weather Data'**
  String get noWeatherDataAvailable;

  /// No description provided for @addCityForWeather.
  ///
  /// In en, this message translates to:
  /// **'Add a city to view weather information'**
  String get addCityForWeather;

  /// No description provided for @weatherDetails.
  ///
  /// In en, this message translates to:
  /// **'Weather Details'**
  String get weatherDetails;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @currentWeather.
  ///
  /// In en, this message translates to:
  /// **'Current Weather'**
  String get currentWeather;

  /// No description provided for @noSchemesFound.
  ///
  /// In en, this message translates to:
  /// **'No schemes found'**
  String get noSchemesFound;

  /// No description provided for @filterSchemes.
  ///
  /// In en, this message translates to:
  /// **'Filter Schemes'**
  String get filterSchemes;

  /// No description provided for @searchSchemes.
  ///
  /// In en, this message translates to:
  /// **'Search schemes...'**
  String get searchSchemes;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @schemeDetails.
  ///
  /// In en, this message translates to:
  /// **'Scheme Details'**
  String get schemeDetails;

  /// No description provided for @mandiPrices.
  ///
  /// In en, this message translates to:
  /// **'Mandi Prices'**
  String get mandiPrices;

  /// No description provided for @selectCommodity.
  ///
  /// In en, this message translates to:
  /// **'Select Commodity'**
  String get selectCommodity;

  /// No description provided for @commodity.
  ///
  /// In en, this message translates to:
  /// **'Commodity'**
  String get commodity;

  /// No description provided for @commodities.
  ///
  /// In en, this message translates to:
  /// **'Commodities'**
  String get commodities;

  /// No description provided for @minPrice.
  ///
  /// In en, this message translates to:
  /// **'Min Price'**
  String get minPrice;

  /// No description provided for @maxPrice.
  ///
  /// In en, this message translates to:
  /// **'Max Price'**
  String get maxPrice;

  /// No description provided for @modalPrice.
  ///
  /// In en, this message translates to:
  /// **'Modal Price'**
  String get modalPrice;

  /// No description provided for @arrivalDate.
  ///
  /// In en, this message translates to:
  /// **'Arrival Date'**
  String get arrivalDate;

  /// No description provided for @plantDisease.
  ///
  /// In en, this message translates to:
  /// **'Plant Disease'**
  String get plantDisease;

  /// No description provided for @scanPlant.
  ///
  /// In en, this message translates to:
  /// **'Scan Plant'**
  String get scanPlant;

  /// No description provided for @diseaseDetection.
  ///
  /// In en, this message translates to:
  /// **'Disease Detection'**
  String get diseaseDetection;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take Picture'**
  String get takePicture;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get analyzing;

  /// No description provided for @diseaseDetected.
  ///
  /// In en, this message translates to:
  /// **'Disease Detected'**
  String get diseaseDetected;

  /// No description provided for @treatment.
  ///
  /// In en, this message translates to:
  /// **'Treatment'**
  String get treatment;

  /// No description provided for @prevention.
  ///
  /// In en, this message translates to:
  /// **'Prevention'**
  String get prevention;

  /// No description provided for @selectModel.
  ///
  /// In en, this message translates to:
  /// **'Select Disease Detection Model'**
  String get selectModel;

  /// No description provided for @chooseModel.
  ///
  /// In en, this message translates to:
  /// **'Choose a pre-trained model to detect plant diseases'**
  String get chooseModel;

  /// No description provided for @loadModel.
  ///
  /// In en, this message translates to:
  /// **'Load Model'**
  String get loadModel;

  /// No description provided for @changeModel.
  ///
  /// In en, this message translates to:
  /// **'Change Model'**
  String get changeModel;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @detect.
  ///
  /// In en, this message translates to:
  /// **'Detect'**
  String get detect;

  /// No description provided for @detectionResult.
  ///
  /// In en, this message translates to:
  /// **'Detection Result'**
  String get detectionResult;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get confidence;

  /// No description provided for @aiRecommendations.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendations'**
  String get aiRecommendations;

  /// No description provided for @possibleCauses.
  ///
  /// In en, this message translates to:
  /// **'Possible Causes'**
  String get possibleCauses;

  /// No description provided for @recommendedSolutions.
  ///
  /// In en, this message translates to:
  /// **'Recommended Solutions'**
  String get recommendedSolutions;

  /// No description provided for @preventiveMeasures.
  ///
  /// In en, this message translates to:
  /// **'Preventive Measures'**
  String get preventiveMeasures;

  /// No description provided for @diseaseScores.
  ///
  /// In en, this message translates to:
  /// **'Disease Scores'**
  String get diseaseScores;

  /// No description provided for @topThree.
  ///
  /// In en, this message translates to:
  /// **'Top 3'**
  String get topThree;

  /// No description provided for @seeMore.
  ///
  /// In en, this message translates to:
  /// **'See More'**
  String get seeMore;

  /// No description provided for @seeLess.
  ///
  /// In en, this message translates to:
  /// **'See Less'**
  String get seeLess;

  /// No description provided for @plantNotDetected.
  ///
  /// In en, this message translates to:
  /// **'🌿 Plant Not Detected'**
  String get plantNotDetected;

  /// No description provided for @detectionError.
  ///
  /// In en, this message translates to:
  /// **'Detection Error'**
  String get detectionError;

  /// No description provided for @usePlantImage.
  ///
  /// In en, this message translates to:
  /// **'Please capture or select an image that clearly shows a plant leaf.'**
  String get usePlantImage;

  /// No description provided for @uncertainDetection.
  ///
  /// In en, this message translates to:
  /// **'Uncertain Detection'**
  String get uncertainDetection;

  /// No description provided for @systemNotSure.
  ///
  /// In en, this message translates to:
  /// **'The system is not sure if this is a plant image'**
  String get systemNotSure;

  /// No description provided for @resultsNotAccurate.
  ///
  /// In en, this message translates to:
  /// **'Results may not be accurate for non-plant images.'**
  String get resultsNotAccurate;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// No description provided for @selectImageToAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Select or capture an image to analyze plant diseases'**
  String get selectImageToAnalyze;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @step1.
  ///
  /// In en, this message translates to:
  /// **'1. Take a photo or select from gallery'**
  String get step1;

  /// No description provided for @step2.
  ///
  /// In en, this message translates to:
  /// **'2. Tap Detect to analyze the image'**
  String get step2;

  /// No description provided for @step3.
  ///
  /// In en, this message translates to:
  /// **'3. View results and recommendations'**
  String get step3;

  /// No description provided for @translating.
  ///
  /// In en, this message translates to:
  /// **'Translating...'**
  String get translating;

  /// No description provided for @translated.
  ///
  /// In en, this message translates to:
  /// **'Translated'**
  String get translated;

  /// No description provided for @yourFarmTools.
  ///
  /// In en, this message translates to:
  /// **'Your Farm Tools'**
  String get yourFarmTools;

  /// No description provided for @aiPoweredInsights.
  ///
  /// In en, this message translates to:
  /// **'Ai-powered insights for your daily decisions'**
  String get aiPoweredInsights;

  /// No description provided for @searchForCrops.
  ///
  /// In en, this message translates to:
  /// **'Search for crops...'**
  String get searchForCrops;

  /// No description provided for @forecasts.
  ///
  /// In en, this message translates to:
  /// **'Forecasts'**
  String get forecasts;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share Post'**
  String get sharePost;

  /// No description provided for @addYourPost.
  ///
  /// In en, this message translates to:
  /// **'add your post'**
  String get addYourPost;

  /// No description provided for @myScheme.
  ///
  /// In en, this message translates to:
  /// **'MyScheme'**
  String get myScheme;

  /// No description provided for @governmentSchemes.
  ///
  /// In en, this message translates to:
  /// **'Government Schemes'**
  String get governmentSchemes;

  /// No description provided for @imd.
  ///
  /// In en, this message translates to:
  /// **'IMD'**
  String get imd;

  /// No description provided for @weatherForecasts.
  ///
  /// In en, this message translates to:
  /// **'Weather Forecasts'**
  String get weatherForecasts;

  /// No description provided for @diseaseDetector.
  ///
  /// In en, this message translates to:
  /// **'Disease Detector'**
  String get diseaseDetector;

  /// No description provided for @detector.
  ///
  /// In en, this message translates to:
  /// **'Detector'**
  String get detector;

  /// No description provided for @offlineAI.
  ///
  /// In en, this message translates to:
  /// **'Offline AI'**
  String get offlineAI;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @testTranslation.
  ///
  /// In en, this message translates to:
  /// **'Test Translation'**
  String get testTranslation;

  /// No description provided for @offlineML.
  ///
  /// In en, this message translates to:
  /// **'offline ML'**
  String get offlineML;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @allLanguages.
  ///
  /// In en, this message translates to:
  /// **'All Languages'**
  String get allLanguages;

  /// No description provided for @mandiPricesList.
  ///
  /// In en, this message translates to:
  /// **'Mandi Prices'**
  String get mandiPricesList;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select District'**
  String get selectDistrict;

  /// No description provided for @selectMarket.
  ///
  /// In en, this message translates to:
  /// **'Select Market'**
  String get selectMarket;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @arrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrival;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @selectStation.
  ///
  /// In en, this message translates to:
  /// **'Select Station'**
  String get selectStation;

  /// No description provided for @station.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get station;

  /// No description provided for @rainfall.
  ///
  /// In en, this message translates to:
  /// **'Rainfall'**
  String get rainfall;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @cloudCover.
  ///
  /// In en, this message translates to:
  /// **'Cloud Cover'**
  String get cloudCover;

  /// No description provided for @selectChat.
  ///
  /// In en, this message translates to:
  /// **'Select Chat'**
  String get selectChat;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @topFarmers.
  ///
  /// In en, this message translates to:
  /// **'Top Farmers'**
  String get topFarmers;

  /// No description provided for @yourRanking.
  ///
  /// In en, this message translates to:
  /// **'Your Ranking'**
  String get yourRanking;

  /// No description provided for @earnPoints.
  ///
  /// In en, this message translates to:
  /// **'Earn points by helping the community!'**
  String get earnPoints;

  /// No description provided for @loadingLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Loading leaderboard...'**
  String get loadingLeaderboard;

  /// No description provided for @yourRank.
  ///
  /// In en, this message translates to:
  /// **'YOUR RANK'**
  String get yourRank;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start your conversation'**
  String get startConversation;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything related to farming, crops, weather, and more.'**
  String get askAnything;

  /// No description provided for @internetConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Internet Connection Required'**
  String get internetConnectionRequired;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkYourConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get checkYourConnection;

  /// No description provided for @translateTo.
  ///
  /// In en, this message translates to:
  /// **'Translate to'**
  String get translateTo;

  /// No description provided for @translatedText.
  ///
  /// In en, this message translates to:
  /// **'Translated Text'**
  String get translatedText;

  /// No description provided for @originalText.
  ///
  /// In en, this message translates to:
  /// **'Original Text'**
  String get originalText;

  /// No description provided for @weatherError.
  ///
  /// In en, this message translates to:
  /// **'Weather Error'**
  String get weatherError;

  /// No description provided for @loadingWeatherFor.
  ///
  /// In en, this message translates to:
  /// **'Loading weather for'**
  String get loadingWeatherFor;

  /// No description provided for @onlineFeatures.
  ///
  /// In en, this message translates to:
  /// **'Online Features'**
  String get onlineFeatures;

  /// No description provided for @offlineFeatures.
  ///
  /// In en, this message translates to:
  /// **'Offline Features'**
  String get offlineFeatures;

  /// No description provided for @speakToAI.
  ///
  /// In en, this message translates to:
  /// **'Speak to AI'**
  String get speakToAI;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @advice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get advice;

  /// No description provided for @govtSchemes.
  ///
  /// In en, this message translates to:
  /// **'Govt schemes'**
  String get govtSchemes;

  /// No description provided for @liveRates.
  ///
  /// In en, this message translates to:
  /// **'Live rates'**
  String get liveRates;

  /// No description provided for @requiresInternet.
  ///
  /// In en, this message translates to:
  /// **'Requires Internet Connection'**
  String get requiresInternet;

  /// No description provided for @cached.
  ///
  /// In en, this message translates to:
  /// **'Cached'**
  String get cached;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineMode;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get ready;

  /// No description provided for @listeningState.
  ///
  /// In en, this message translates to:
  /// **'LISTENING'**
  String get listeningState;

  /// No description provided for @processingState.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING'**
  String get processingState;

  /// No description provided for @streamingState.
  ///
  /// In en, this message translates to:
  /// **'STREAMING'**
  String get streamingState;

  /// No description provided for @speakingState.
  ///
  /// In en, this message translates to:
  /// **'SPEAKING'**
  String get speakingState;

  /// No description provided for @errorState.
  ///
  /// In en, this message translates to:
  /// **'ERROR'**
  String get errorState;

  /// No description provided for @oopsSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Oops! Something went wrong'**
  String get oopsSomethingWrong;
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
      <String>['en', 'hi', 'ml'].contains(locale.languageCode);

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
    case 'ml':
      return AppLocalizationsMl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
