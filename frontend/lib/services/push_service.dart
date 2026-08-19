import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'api_exception.dart';

/// Push notifications for calendar reminders.
///
/// The server does the scheduling — it sends the day before at 22:00 and again
/// 30 minutes ahead, and stays quiet between 23:00 and 08:00 KST. All the app
/// has to do is hand over an FCM token and keep it current.
class PushService {
  const PushService._();

  static const PushService instance = PushService._();

  /// Wires up Firebase. Safe to call more than once.
  ///
  /// Separate from [register] because this has to happen before `runApp`,
  /// while registration can only run once the user is signed in — the server
  /// stores the token against an account.
  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();

    // A token can be reissued at any time — app reinstall, cache clear, or
    // Firebase's own rotation. Miss it and the phone quietly stops getting
    // reminders, so re-register whenever it changes.
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (ApiClient.instance.isLoggedIn) {
        _send(token);
      }
    });
  }

  /// Asks for permission and registers this device. Call right after login.
  ///
  /// Returns the token, or null when the user declined or Firebase has no
  /// token to give. **A refusal is not an error** — the rest of the app works
  /// fine without notifications, so callers should carry on either way.
  Future<String?> register() async {
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return null;

    await _send(token);
    return token;
  }

  /// Stops notifications for this device. Logout does the same thing server
  /// side, so this is for a "notifications off" toggle.
  Future<void> unregister() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await ApiClient.instance.delete('/api/devices', body: {'fcmToken': token});
    } on ApiException catch (e) {
      debugPrint('Device unregister failed: ${e.code}');
    }
  }

  /// The token, for handing to `AuthService.logout` so the server can drop
  /// this device as part of signing out.
  Future<String?> currentToken() => FirebaseMessaging.instance.getToken();

  /// Messages that arrive while the app is open. Android does not draw a
  /// notification for these, so show them in-app if you want them seen.
  static Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;

  /// Fires when a notification is tapped and the app was already running in
  /// the background. Use `data['eventId']` to open the right schedule.
  static Stream<RemoteMessage> get onNotificationTap =>
      FirebaseMessaging.onMessageOpenedApp;

  /// The notification that launched the app from cold, if any.
  static Future<RemoteMessage?> initialMessage() =>
      FirebaseMessaging.instance.getInitialMessage();

  static Future<void> _send(String token) async {
    try {
      await ApiClient.instance.post('/api/devices', body: {
        'fcmToken': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'IOS' : 'ANDROID',
      });
    } on ApiException catch (e) {
      // Never let this break the login flow. Losing reminders is worse than
      // nothing, but being unable to sign in is worse still.
      debugPrint('Device register failed: ${e.code} ${e.message}');
    }
  }
}
