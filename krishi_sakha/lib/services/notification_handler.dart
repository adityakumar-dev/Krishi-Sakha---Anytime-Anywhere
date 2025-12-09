import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:krishi_sakha/apis/app_global.dart';
import 'package:krishi_sakha/utils/routes/routes.dart';

/// Notification types for routing
enum NotificationType {
  weatherAlert,
  cropTip,
  communityPost,
  expertPost,
  schemeUpdate,
  priceUpdate,
  general,
}

/// Service to handle notification navigation and actions
class NotificationHandler {
  static bool _isHandling = false;
  
  /// Handle notification tap and navigate to appropriate screen
  static void handleNotificationTap(Map<String, dynamic> data) {
    print('📬 Handling notification tap with data: $data');

    // Prevent multiple simultaneous navigation attempts
    if (_isHandling) {
      print('⏳ Already handling a notification, skipping...');
      return;
    }

    _isHandling = true;

    try {
      final type = _getNotificationType(data);
      
      // Try to get context, retry if not available
      _navigateWithRetry(type, data);
    } catch (e) {
      print('❌ Error handling notification: $e');
      _isHandling = false;
    }
  }

  /// Navigate with retry mechanism for when app is initializing
  static void _navigateWithRetry(NotificationType type, Map<String, dynamic> data, {int attempt = 0}) {
    final context = AppGlobal.navigatorKey.currentContext;

    if (context == null) {
      if (attempt < 10) {
        print('⏳ Context not ready, retrying... (attempt ${attempt + 1}/10)');
        Future.delayed(Duration(milliseconds: 300 * (attempt + 1)), () {
          _navigateWithRetry(type, data, attempt: attempt + 1);
        });
      } else {
        print('❌ Context not available after 10 attempts, giving up');
        _isHandling = false;
      }
      return;
    }

    print('✅ Context available, navigating to screen...');

    try {
      switch (type) {
        case NotificationType.weatherAlert:
          _handleWeatherAlert(context, data);
          break;
        case NotificationType.cropTip:
          _handleCropTip(context, data);
          break;
        case NotificationType.communityPost:
          _handleCommunityPost(context, data);
          break;
        case NotificationType.expertPost:
          _handleExpertPost(context, data);
          break;
        case NotificationType.schemeUpdate:
          _handleSchemeUpdate(context, data);
          break;
        case NotificationType.priceUpdate:
          _handlePriceUpdate(context, data);
          break;
        case NotificationType.general:
          _handleGeneral(context, data);
          break;
      }
      
      // Reset flag after navigation
      Future.delayed(const Duration(milliseconds: 500), () {
        _isHandling = false;
      });
    } catch (e) {
      print('❌ Error during navigation: $e');
      _isHandling = false;
    }
  }

  /// Determine notification type from data
  static NotificationType _getNotificationType(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase() ?? '';
    final screen = data['screen']?.toString().toLowerCase() ?? '';
    
    print('🔍 Determining notification type:');
    print('   type: "$type"');
    print('   screen: "$screen"');

    if (type.contains('weather') || screen.contains('weather')) {
      print('   ✅ Identified as: Weather Alert');
      return NotificationType.weatherAlert;
    } else if (type.contains('crop') || screen.contains('crop')) {
      print('   ✅ Identified as: Crop Tip');
      return NotificationType.cropTip;
    } else if (type.contains('community') || type.contains('post')) {
      print('   ✅ Identified as: Community Post');
      return NotificationType.communityPost;
    } else if (type.contains('expert')) {
      print('   ✅ Identified as: Expert Post');
      return NotificationType.expertPost;
    } else if (type.contains('scheme') || type.contains('yojana')) {
      print('   ✅ Identified as: Scheme Update');
      return NotificationType.schemeUpdate;
    } else if (type.contains('price') || type.contains('mandi')) {
      print('   ✅ Identified as: Price Update');
      return NotificationType.priceUpdate;
    }

    print('   ✅ Identified as: General');
    return NotificationType.general;
  }

  /// Handle weather alert notification
  static void _handleWeatherAlert(BuildContext context, Map<String, dynamic> data) {
    print('🌦️ Handling weather alert notification');
    print('🌦️ Attempting to navigate to: ${AppRoutes.weather}');
    
    try {
      // Navigate to OpenMeteo weather screen with user's location
      context.push(AppRoutes.weather);
      print('✅ Navigation to weather screen initiated');
    } catch (e) {
      print('❌ Error navigating to weather screen: $e');
    }
  }

  /// Handle crop tip notification
  static void _handleCropTip(BuildContext context, Map<String, dynamic> data) {
    print('🌾 Navigating to crop advice');
    
    // Navigate to home screen or specific crop section
    context.push(AppRoutes.home);
  }

  /// Handle community post notification
  static void _handleCommunityPost(BuildContext context, Map<String, dynamic> data) {
    print('👥 Navigating to community posts');
    
    final postId = data['post_id'] ?? data['postId'];
    
    // Navigate to posts screen
    context.push(AppRoutes.posts);
    
    // If specific post ID is provided, you can navigate to post detail
    // This would require adding a post detail route
    if (postId != null) {
      print('📝 Post ID: $postId');
      // context.push('${AppRoutes.posts}/$postId');
    }
  }

  /// Handle expert post notification
  static void _handleExpertPost(BuildContext context, Map<String, dynamic> data) {
    print('🎓 Navigating to expert posts');
    
    context.push(AppRoutes.expertPosts);
  }

  /// Handle scheme update notification
  static void _handleSchemeUpdate(BuildContext context, Map<String, dynamic> data) {
    print('📋 Navigating to schemes');
    
    final schemeId = data['scheme_id'] ?? data['schemeId'];
    
    // Navigate to schemes screen
    context.push(AppRoutes.schemes);
    
    if (schemeId != null) {
      print('🆔 Scheme ID: $schemeId');
    }
  }

  /// Handle price update notification
  static void _handlePriceUpdate(BuildContext context, Map<String, dynamic> data) {
    print('💰 Navigating to mandi prices');
    
    // Navigate to mandi price screen
    context.push(AppRoutes.mandiStateSelect);
  }

  /// Handle general notification
  static void _handleGeneral(BuildContext context, Map<String, dynamic> data) {
    print('📢 General notification - navigating to home');
    
    // Check if there's a custom screen parameter
    final screen = data['screen']?.toString();
    
    if (screen != null) {
      final route = _getRouteFromScreenName(screen);
      if (route != null) {
        context.push(route);
        return;
      }
    }
    
    // Default to home screen
    context.push(AppRoutes.home);
  }

  /// Map screen name to route
  static String? _getRouteFromScreenName(String screenName) {
    final screen = screenName.toLowerCase();
    
    if (screen.contains('weather')) return AppRoutes.weather;
    if (screen.contains('imd')) return AppRoutes.imdWeather;
    if (screen.contains('post')) return AppRoutes.posts;
    if (screen.contains('expert')) return AppRoutes.expertPosts;
    if (screen.contains('scheme')) return AppRoutes.schemes;
    if (screen.contains('mandi') || screen.contains('price')) return AppRoutes.mandiStateSelect;
    if (screen.contains('profile')) return AppRoutes.profile;
    if (screen.contains('leaderboard')) return AppRoutes.leaderboard;
    if (screen.contains('chat')) return AppRoutes.chatServer;
    if (screen.contains('disease')) return AppRoutes.plantDisease;
    if (screen.contains('satellite')) return AppRoutes.satteliteView;
    if (screen.contains('search')) return AppRoutes.search;
    if (screen.contains('voice')) return AppRoutes.voiceChat;
    
    return null;
  }

  /// Show in-app notification banner
  static void showInAppNotification({
    required BuildContext context,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(message),
          ],
        ),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        action: data != null
            ? SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  handleNotificationTap(data);
                },
              )
            : null,
      ),
    );
  }
}
