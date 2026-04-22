import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/push_tokens_api.dart';
import '../routes/navigation.dart';
import 'auth_service.dart';

/// FCM Push notifications (Android/iOS).
///
/// Requirements:
/// - Android: `android/app/google-services.json`
/// - iOS: `ios/Runner/GoogleService-Info.plist` (if iOS target)
/// - Call [PushNotificationService.init] once at app startup.
class PushNotificationService {
  PushNotificationService._();

  static const String _prefEnabledKey = 'notification_enabled';

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Firebase init (no-op if already initialized)
    try {
      await Firebase.initializeApp();
    } catch (_) {}

    // Background handler must be registered early.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _initLocalNotifications();

    // iOS/Android permission request (Android 13+ also uses runtime permission)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Token (you will typically POST this to backend)
    final token = await FirebaseMessaging.instance.getToken();
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FCM] token=$token');
    }
    await syncTokenToBackend();

    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      await syncTokenToBackend(tokenOverride: t);
    });

    // Foreground messages → show local notification (if enabled)
    FirebaseMessaging.onMessage.listen((m) async {
      final enabled = await _isEnabled();
      if (!enabled) return;
      await _showLocal(m);
    });

    // App opened from notification (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpen);

    // App opened from terminated state
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handleOpen(initial);
    }
  }

  static Future<bool> _isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabledKey) ?? true;
  }

  static Future<void> syncTokenToBackend({String? tokenOverride}) async {
    final token = tokenOverride ?? await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    final enabled = await _isEnabled();
    if (!enabled) return;
    final loggedIn = await AuthService.isLoggedIn();
    if (!loggedIn) return;
    try {
      await PushTokensApi.upsert(token: token, platform: 'android');
    } catch (_) {}
  }

  static Future<void> deleteTokenFromBackend() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await PushTokensApi.delete(token: token);
    } catch (_) {}
  }

  static Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);

    await _local.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _navigateFromData(data);
        } catch (_) {}
      },
    );

    const channel = AndroidNotificationChannel(
      'default',
      '일등대리 알림',
      description: '운행/결제/문의 등 주요 알림',
      importance: Importance.high,
    );

    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> _showLocal(RemoteMessage m) async {
    final n = m.notification;
    final title = n?.title ?? '알림';
    final body = n?.body ?? '';
    final payload = jsonEncode(m.data);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'default',
        '일등대리 알림',
        channelDescription: '운행/결제/문의 등 주요 알림',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  static void _handleOpen(RemoteMessage m) {
    _navigateFromData(m.data);
  }

  /// Data contract:
  /// - route: named route (e.g. "/notice")
  /// - rideId: for deep links (optional)
  /// - type: reserved for future routing (optional)
  static void _navigateFromData(Map<String, dynamic> data) {
    // Prefer explicit route; otherwise, fallback to home for common types.
    final explicit = data['route']?.toString();
    final type = data['type']?.toString();
    final rideId = data['rideId']?.toString();

    final route = (explicit != null && explicit.isNotEmpty)
        ? explicit
        : (type == 'ride_status' && (rideId ?? '').isNotEmpty)
            ? '/home'
            : null;
    if (route == null) return;

    navigatorKey.currentState?.pushNamed(route, arguments: data);
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // Background 처리 로직이 필요하면 여기서 수행 (서버 ack 등)
}

