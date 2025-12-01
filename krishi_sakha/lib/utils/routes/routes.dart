import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/apis/app_global.dart';
import 'package:krishi_sakha/screens/chat/server/select_chat.dart';
import 'package:krishi_sakha/screens/home/home_screen.dart';
import 'package:krishi_sakha/screens/login/login_screen.dart';
import 'package:krishi_sakha/screens/models/model_list_screen.dart';
import 'package:krishi_sakha/screens/onboarding/onboarding.dart';
import 'package:krishi_sakha/screens/onboarding/profile_onboard_screen.dart';
import 'package:krishi_sakha/screens/permission/permission_screen.dart';
import 'package:krishi_sakha/screens/plant_disease/plant_disease_screen.dart';
import 'package:krishi_sakha/screens/posts/create_post_screen.dart';
import 'package:krishi_sakha/screens/posts/exper_post_scree.dart';
import 'package:krishi_sakha/screens/posts/posts_screen.dart';
import 'package:krishi_sakha/screens/posts/saved_posts_screen.dart';
import 'package:krishi_sakha/screens/profile/profile_screen.dart';
import 'package:krishi_sakha/screens/sattelite_view/sattelite_view_screen.dart';
import 'package:krishi_sakha/screens/leaderboard/leaderboard_screen.dart';
import 'package:krishi_sakha/screens/search/ai_search_screen.dart';
import 'package:krishi_sakha/screens/settings/settings_screen.dart';
import 'package:krishi_sakha/screens/schemes/schemes_screen.dart';
import 'package:krishi_sakha/screens/splash/splash_screen.dart';
import 'package:krishi_sakha/screens/translation/test_offline_translation.dart';
import 'package:krishi_sakha/screens/translation/test_translation.dart';
import 'package:krishi_sakha/screens/voice/voice_screen.dart';
import 'package:krishi_sakha/screens/weather/weather_screen.dart';

// Route paths
class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/';
  static const String permission = '/permission';
  static const String home = '/home';
  static const String chat = '/chat';
  static const String chatHistory = '/chat-history';
  static const String settings = '/settings';
  static const String download = '/download';
  static const String search = '/search';
  static const String login = "/login";
  static const String selector = "/selector";
  static const String chatServer = "/chat-server";
  static const String voiceChat = "/voice-chat";
  static const String weather = "/weather";
  static const String cropAdvice = "/crop-advice";
  static const String plantDisease = "/plant-disease";
  static const String satteliteView = "/sattelite-view";
  static const String profileOnboard = "/profile-onboard";
  static const String createPost = "/create-post";
  static const String posts = "/posts";
  static const String profile = "/profile";
  static const String expertPosts = "/expert-posts";
  static const String savedPosts = "/saved-posts";
  static const String leaderboard = "/leaderboard";
  static const String schemes = "/schemes";
  static const String test_translation = "/test-translation";
  static const String test_offline_translation = "/test-offline-translation";
  
}

// GoRouter configuration
final GoRouter appRouter = GoRouter(

  initialLocation: AppRoutes.splash,
  navigatorKey:  AppGlobal.navigatorKey,
  routes: [

    GoRoute(path: AppRoutes.test_translation, name: 'test_translation', builder: (context, state) => const TestTranslationScreen()),
    GoRoute(path: AppRoutes.test_offline_translation, name: 'test_offline_translation', builder: (context, state) => const TestOfflineTranslationScreen()),
    GoRoute(path: AppRoutes.satteliteView, name: 'satteliteView', builder: (context, state) => const SatteliteViewScreen()),

    GoRoute(path: AppRoutes.plantDisease, name: 'plantDisease', builder: (context, state) => const PlantDiseaseScreen()),
  GoRoute(path: AppRoutes.voiceChat, name: 'voiceChat', builder: (context, state) => const VoiceScreen()),
    GoRoute(path: AppRoutes.chatServer, name: 'chatServer', builder: (context, state) => const SelectChatScreen()),
    GoRoute(path: AppRoutes.weather, name: 'weather', builder: (context, state) => const WeatherScreen()),
    GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
    GoRoute(path: AppRoutes.chatHistory, name: 'chatHistory', builder: (context, state) => const SelectChatScreen()),
    GoRoute(path: AppRoutes.posts, name: 'posts', builder: (context, state) => const PostsScreen()),
    GoRoute(path: AppRoutes.createPost, name: 'createPost', builder: (context, state) => const CreatePostScreen()),
    GoRoute(path: AppRoutes.expertPosts, name: 'expertPosts', builder: (context, state) => const ExpertPostsScreen()),
    GoRoute(path: AppRoutes.profile, name: 'profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: AppRoutes.savedPosts, name: 'savedPosts', builder: (context, state) => const SavedPostsScreen()),
    GoRoute(path: AppRoutes.leaderboard, name: 'leaderboard', builder: (context, state) => const LeaderboardScreen()),
    GoRoute(path: AppRoutes.schemes, name: 'schemes', builder: (context, state) => const SchemesScreen()),
    // Onboarding route
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Permission route
    GoRoute(
      path: AppRoutes.permission,
      name: 'permission',
      builder: (context, state) => const PermissionScreen(),
    ),

    // Home route (placeholder for now)
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Profile Onboarding route
    GoRoute(
      path: AppRoutes.profileOnboard,
      name: 'profileOnboard',
      builder: (context, state) => const ProfileOnboardScreen(),
    ),
  GoRoute(
      path: AppRoutes.selector,
      name: 'selector',
      builder: (context, state) => ModelListScreen(),
    ),  

  GoRoute(path: AppRoutes.login, name: 'login', builder: (context, state) => const LoginScreen()),


    // Settings route (placeholder for now)
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),

    // Download route (placeholder for now)
    GoRoute(
      path: AppRoutes.download,
      name: 'download',
      builder: (context, state) => const DownloadScreen(),
    ),

    // Search route (placeholder for now)
    GoRoute(
      path: AppRoutes.search,
      name: 'search',
      builder: (context, state) => const AISearchScreen(),
    ),
 
    
  ],

  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Page not found: ${state.uri}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.onboarding),
            child: const Text('Go to Home'),
          ),
        ],
      ),
    ),
  ),
);

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: const Color(0xFF101820),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Chat Screen - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

// class SettingsScreen extends StatelessWidget {
//   const SettingsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Settings'),
//         backgroundColor: const Color(0xFF101820),
//         foregroundColor: Colors.white,
//       ),
//       body: const Center(
//         child: Text(
//           'Settings Screen - Coming Soon',
//           style: TextStyle(fontSize: 18),
//         ),
//       ),
//     );
//   }
// }

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Models'),
        backgroundColor: const Color(0xFF101820),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Download Screen - Coming Soon',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
