import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:krishi_sakha/services/notification_handler.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Background message received: ${message.messageId}");
  print("🔔 Background message data: ${message.data}");
  // Don't show local notification here - FCM automatically shows it when app is in background/terminated
  // This handler is only for processing data (e.g., saving to local storage)
}

class NotificationManager {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channel for Android - must match FCM default channel for heads-up
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications that pop up.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    showBadge: true,
  );

  // Callback for handling notification taps
  static void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Initialize the notification service
  static Future<void> init({
    void Function(Map<String, dynamic> data)? onTap,
    bool enableUserSpecificNotifications = true,
  }) async {
    // Use NotificationHandler if no custom onTap provided
    onNotificationTap = onTap ?? NotificationHandler.handleNotificationTap;

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initLocalNotifications();

    // Create notification channel for Android
    await _createNotificationChannel();

    // Set FCM to show foreground notifications and use our channel
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was terminated
    await _handleInitialMessage();

    // Subscribe to default topics for general notifications
    await subscribeToTopic('global_updates');
    
    // User-specific notifications are enabled by default
    // These will be sent to individual users via their FCM tokens stored in Supabase
    if (enableUserSpecificNotifications) {
      print("✅ User-specific notifications enabled");
      print("📌 Send notifications to users via their stored FCM tokens in Supabase");
    }

    // Get and print FCM token (useful for testing)
    final token = await getToken();
    print("📱 FCM Token: $token");
  }

  /// Request notification permissions
  static Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔐 Permission status: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Initialize local notifications plugin
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// Create Android notification channel
  static Future<void> _createNotificationChannel() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  /// Handle notification response (tap)
  static void _onNotificationResponse(NotificationResponse response) {
    print("📬 Local notification tapped");
    print("📬 Notification ID: ${response.id}");
    print("📬 Action ID: ${response.actionId}");
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        print("📬 Parsed notification data: $data");
        
        if (data.isNotEmpty) {
          onNotificationTap?.call(data);
        } else {
          print("⚠️ Empty data payload");
        }
      } catch (e) {
        print("❌ Error parsing notification payload: $e");
        print("❌ Raw payload: ${response.payload}");
      }
    } else {
      print("⚠️ No payload in notification response");
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print("📩 Foreground message: ${message.notification?.title}");
    await showLocalNotification(message);
  }

  /// Handle notification tap (background state)
  static void _handleNotificationTap(RemoteMessage message) {
    print("📬 Message opened from background");
    print("📬 Notification title: ${message.notification?.title}");
    print("📬 Notification body: ${message.notification?.body}");
    print("📬 Data payload: ${message.data}");
    
    if (message.data.isNotEmpty) {
      onNotificationTap?.call(message.data);
    } else {
      print("⚠️ No data payload in notification");
    }
  }

  /// Handle initial message (app opened from terminated state)
  static Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      print("🚀 App opened from terminated state via notification");
      print("🚀 Notification title: ${message.notification?.title}");
      print("🚀 Notification body: ${message.notification?.body}");
      print("🚀 Data payload: ${message.data}");
      
      // Longer delay to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (message.data.isNotEmpty) {
          print("🚀 Triggering navigation with data: ${message.data}");
          onNotificationTap?.call(message.data);
        } else {
          print("⚠️ No data payload in notification");
        }
      });
    } else {
      print("ℹ️ App started normally (not from notification)");
    }
  }

  /// Show local notification
  static Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title ?? 'Krishi Sakha',
        notification.body ?? '',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.max,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            color: const Color(0xFF4CAF50), // Green color for agriculture app
            fullScreenIntent: true, // Enables heads-up notification
            visibility: NotificationVisibility.public,
            category: AndroidNotificationCategory.message,
            ticker: notification.title,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Show a custom notification
  static Future<void> showCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    await _localNotifications.show(
      id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF4CAF50),
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.message,
          ticker: title,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print("✅ Subscribed to topic: $topic");
    } catch (e) {
      print("❌ Failed to subscribe to topic $topic: $e");
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print("✅ Unsubscribed from topic: $topic");
    } catch (e) {
      print("❌ Failed to unsubscribe from topic $topic: $e");
    }
  }

  /// Subscribe to multiple topics
  static Future<void> subscribeToTopics(List<String> topics) async {
    for (final topic in topics) {
      await subscribeToTopic(topic);
    }
  }

  /// Unsubscribe from multiple topics
  static Future<void> unsubscribeFromTopics(List<String> topics) async {
    for (final topic in topics) {
      await unsubscribeFromTopic(topic);
    }
  }

  /// Subscribe to location-based topic (e.g., state/district alerts)
  static Future<void> subscribeToLocationAlerts(String location) async {
    final sanitizedLocation = location.toLowerCase().replaceAll(' ', '_');
    await subscribeToTopic('location_$sanitizedLocation');
  }

  /// Subscribe to crop-specific topic
  static Future<void> subscribeToCropAlerts(String cropName) async {
    final sanitizedCrop = cropName.toLowerCase().replaceAll(' ', '_');
    await subscribeToTopic('crop_$sanitizedCrop');
  }

  /// Delete FCM token (useful for logout)
  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
    print("🗑️ FCM token deleted");
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}