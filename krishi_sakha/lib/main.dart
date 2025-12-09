import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:krishi_sakha/l10n/app_localizations.dart';
import 'package:krishi_sakha/models/weather_model.dart';
import 'package:krishi_sakha/models/imd_weather_model.dart';
import 'package:krishi_sakha/providers/agri_chat_provider.dart';
import 'package:krishi_sakha/providers/ai_search_provider.dart';
import 'package:krishi_sakha/providers/language_provider.dart';
import 'package:krishi_sakha/providers/plant_disease_provider.dart';
import 'package:krishi_sakha/providers/server_chat_handler_provider.dart';
import 'package:krishi_sakha/providers/unified_translation_provider.dart';
import 'package:krishi_sakha/providers/void_provider.dart';
import 'package:krishi_sakha/providers/profile_provider.dart';
import 'package:krishi_sakha/providers/imd_weather_provider.dart';
import 'package:krishi_sakha/providers/post_manage_provider.dart';
import 'package:krishi_sakha/providers/leaderboard_provider.dart';
import 'package:krishi_sakha/providers/scheme_provider.dart';
import 'package:krishi_sakha/providers/scheme_detail_provider.dart';
import 'package:krishi_sakha/providers/weather_provider.dart';
import 'package:krishi_sakha/providers/mandi_provider.dart';
import 'package:krishi_sakha/services/notification_manager.dart';
import 'package:krishi_sakha/services/fcm_token_service.dart';
import 'package:krishi_sakha/services/notification_handler.dart';
import 'package:krishi_sakha/utils/ui/set_system_ui_overlay.dart';
import 'package:provider/provider.dart';
import 'package:krishi_sakha/models/llm_model.dart';
import 'package:krishi_sakha/models/users_model.dart';
import 'package:krishi_sakha/models/post_model.dart';
import 'package:krishi_sakha/models/scheme_meta_model.dart';
import 'package:krishi_sakha/providers/model_provider.dart';
import 'package:krishi_sakha/providers/llama_provider.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  setSystemUIOverlayStyle();

  await Hive.initFlutter();


  Hive.registerAdapter(LlmModelAdapter());
  Hive.registerAdapter(WeatherDataAdapter());
  Hive.registerAdapter(CurrentWeatherAdapter());
  Hive.registerAdapter(DailyWeatherAdapter());
  Hive.registerAdapter(CityLocationAdapter());
  Hive.registerAdapter(WeatherDataContainerAdapter());
  // IMD weather adapters
  Hive.registerAdapter(ImdWeatherResponseAdapter());
  Hive.registerAdapter(ImdForecastDayAdapter());
  Hive.registerAdapter(UsersModelAdapter());
  Hive.registerAdapter(PostModelAdapter());
  Hive.registerAdapter(SchemeModelAdapter());
  Hive.registerAdapter(SchemeFilterModelAdapter());
  
// setup Firebase
await Firebase.initializeApp(
    options: await platformOptions(),
  );

  // Initialize Firebase Cloud Messaging notifications with navigation handler
  await NotificationManager.init(
    onTap: NotificationHandler.handleNotificationTap,
    enableUserSpecificNotifications: true,
  );

  // Listen for FCM token refresh and update in database
  FcmTokenService.listenToTokenRefresh();

  // Open userdata box explicitly
  
  await Supabase.initialize(
    url: dotenv.env['URL'] ?? '',
    anonKey: dotenv.env['ANON_PUBLIC_KEY'] ?? '',
  );

  runApp(const MyApp());
}

Future<FirebaseOptions> platformOptions() async{
  if(Platform.isAndroid){
    return FirebaseOptions(
      apiKey: dotenv.env['ANDROID_API_KEY'] ?? "",
      appId: dotenv.env['ANDROID_APP_ID'] ?? "",
      messagingSenderId: dotenv.env['ANDROID_MESSAGING_SENDER_ID'] ?? "",
      projectId: dotenv.env['ANDROID_PROJECT_ID'] ?? "",
      storageBucket: dotenv.env['ANDROID_STORAGE_BUCKET'] ?? "" ,
    );
  }
  
  return FirebaseOptions(
    apiKey: dotenv.env['IOS_API_KEY'] ?? "",
    appId: dotenv.env['IOS_APP_ID'] ?? "",
    messagingSenderId: dotenv.env['IOS_MESSAGING_SENDER_ID'] ?? "",
    projectId: dotenv.env['IOS_PROJECT_ID'] ?? "",
    storageBucket: dotenv.env['IOS_STORAGE_BUCKET'] ?? "" ,
    iosBundleId: dotenv.env['IOS_BUNDLE_ID'] ?? "",
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = LanguageProvider();
            // Load saved locale on app start
            provider.loadSavedLocale();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
        ChangeNotifierProvider(create: (_) => LlamaProvider()),
        ChangeNotifierProvider(create: (_) => ServerChatHandlerProvider()),
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ImdWeatherProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => AISearchProvider()),
        ChangeNotifierProvider(create: (_) => PlantDiseaseProvider()),
        ChangeNotifierProvider(create: (_) => PostManageProvider()),
        ChangeNotifierProvider(create: (_) => LeaderboardProvider()),
        ChangeNotifierProvider(create: (_) => SchemeProvider()),
        ChangeNotifierProvider(create: (_) => SchemeDetailProvider()),
        ChangeNotifierProvider(create: (_) => UnifiedTranslationProvider()),
        ChangeNotifierProvider(create: (_) => ImdWeatherProvider()),
        ChangeNotifierProvider(create: (_) => MandiProvider()),
        ChangeNotifierProvider(create: (_) => AgriChatProvider())
        
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp.router(
            title: 'Krishi Sakha',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              useMaterial3: true,
            ),
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en'),
              Locale('hi'),
              Locale('ml'),
            ],
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
