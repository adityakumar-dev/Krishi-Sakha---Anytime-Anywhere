import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to manage FCM tokens in Supabase
class FcmTokenService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Track if token save is in progress to prevent duplicates
  static bool _isSaving = false;
  static String? _lastSavedToken;
  static DateTime? _lastSaveTime;

  /// Save or update FCM token for the current user
  static Future<bool> saveFcmToken({bool force = false}) async {
    try {
      // Prevent duplicate saves
      if (_isSaving && !force) {
        print('⏳ Token save already in progress, skipping...');
        return false;
      }

      // Get current user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return false;
      }

      // Get FCM token
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        print('❌ Failed to get FCM token');
        return false;
      }

      // Check if we recently saved this exact token (within last 5 seconds)
      if (!force && 
          _lastSavedToken == fcmToken && 
          _lastSaveTime != null && 
          DateTime.now().difference(_lastSaveTime!) < const Duration(seconds: 5)) {
        print('⏭️ Token already saved recently, skipping...');
        return true;
      }

      _isSaving = true;

      print('📱 FCM Token: $fcmToken');
      print('👤 User ID: ${user.id}');

      // Check if token already exists for this user
      final existingTokens = await _supabase
          .from('user_fcm_tokens')
          .select()
          .eq('user_id', user.id)
          .eq('fcm_token', fcmToken);

      if (existingTokens.isEmpty) {
        // Insert new token
        await _supabase.from('user_fcm_tokens').insert({
          'user_id': user.id,
          'fcm_token': fcmToken,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        print('✅ FCM token saved successfully');
      } else {
        // Update existing token's timestamp
        await _supabase
            .from('user_fcm_tokens')
            .update({
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', user.id)
            .eq('fcm_token', fcmToken);
        print('✅ FCM token updated successfully');
      }

      _lastSavedToken = fcmToken;
      _lastSaveTime = DateTime.now();
      _isSaving = false;

      return true;
    } catch (e) {
      print('❌ Error saving FCM token: $e');
      _isSaving = false;
      return false;
    }
  }

  /// Delete FCM token for the current user (useful for logout)
  static Future<bool> deleteFcmToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return false;
      }

      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        print('❌ Failed to get FCM token');
        return false;
      }

      // Delete token from database
      await _supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('fcm_token', fcmToken);

      // Delete token from Firebase
      await _messaging.deleteToken();

      print('✅ FCM token deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
      return false;
    }
  }

  /// Delete all FCM tokens for the current user
  static Future<bool> deleteAllUserTokens() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return false;
      }

      await _supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', user.id);

      print('✅ All FCM tokens deleted for user');
      return true;
    } catch (e) {
      print('❌ Error deleting all user tokens: $e');
      return false;
    }
  }

  /// Get all FCM tokens for the current user
  static Future<List<String>> getUserTokens() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No authenticated user found');
        return [];
      }

      final response = await _supabase
          .from('user_fcm_tokens')
          .select('fcm_token')
          .eq('user_id', user.id);

      return (response as List)
          .map((e) => e['fcm_token'] as String)
          .toList();
    } catch (e) {
      print('❌ Error getting user tokens: $e');
      return [];
    }
  }

  /// Clean up old/expired tokens (tokens not updated in last 90 days)
  static Future<void> cleanupOldTokens() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));

      await _supabase
          .from('user_fcm_tokens')
          .delete()
          .eq('user_id', user.id)
          .lt('updated_at', ninetyDaysAgo.toIso8601String());

      print('✅ Old FCM tokens cleaned up');
    } catch (e) {
      print('❌ Error cleaning up old tokens: $e');
    }
  }

  /// Listen to FCM token refresh and update in database
  static void listenToTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM token refreshed: $newToken');
      await saveFcmToken();
    });
  }
}
