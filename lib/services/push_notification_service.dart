import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  static const String _channelIdDefault = 'default';
  static const String _channelName = '일등대리 알림';
  static const String _channelDesc = '운행/결제/문의 등 주요 알림';

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
      final platform = Platform.isIOS ? 'ios' : 'android';
      await PushTokensApi.upsert(token: token, platform: platform);
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
      _channelIdDefault,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  static _NotificationSpec _compose(RemoteMessage m) {
    final data = m.data;
    final type = (data['type'] ?? '').toString();

    // Prefer explicit FCM notification fields, fallback to data keys.
    final rawTitle = m.notification?.title ?? data['title']?.toString();
    final rawBody = m.notification?.body ?? data['body']?.toString();

    // Some backends may omit type for ride updates but still send status keys.
    final hasRideStatusLike =
        data.containsKey('status') || data.containsKey('rideStatus');

    // Type-based tone (color, group, copy).
    switch (type) {
      case 'ride_status':
      case 'dispatch':
      case 'ride':
      case 'call':
      case 'driver':
      case 'driver_arrived':
        final status = (data['status'] ?? data['rideStatus'] ?? '').toString();
        final rideId = (data['rideId'] ?? '').toString();
        final driverName = (data['driverName'] ?? '').toString().trim();
        final title = (rawTitle?.trim().isNotEmpty ?? false)
            ? rawTitle!.trim()
            : _rideStatusTitle(status);
        final body = (rawBody?.trim().isNotEmpty ?? false)
            ? rawBody!.trim()
            : _rideStatusBody(status, rideId: rideId, driverName: driverName);
        return _NotificationSpec(
          title: title.isEmpty ? '배차 알림' : title,
          body: body,
          groupKey: 'ride',
          color: const Color(0xFF1A2F7A),
          category: AndroidNotificationCategory.status,
        );
      case 'payment':
      case 'mileage':
      case 'mileage_adjust':
      case 'mileage_changed':
      case 'mileage_update':
        final amount = _toInt(data['amount']);
        final balance = _toInt(data['balance']);
        final title = (rawTitle?.trim().isNotEmpty ?? false)
            ? rawTitle!.trim()
            : (amount >= 0 ? '마일리지 적립' : '마일리지 차감');
        final body = (rawBody?.trim().isNotEmpty ?? false)
            ? rawBody!.trim()
            : _mileageBody(amount: amount, balance: balance);
        return _NotificationSpec(
          title: title,
          body: body,
          groupKey: 'payment',
          color: const Color(0xFF1E88E5),
          category: AndroidNotificationCategory.message,
        );
      case 'inquiry':
      case 'qa':
        return _NotificationSpec(
          title: (rawTitle?.trim().isNotEmpty ?? false) ? rawTitle!.trim() : '문의 답변 알림',
          body: (rawBody ?? '').toString(),
          groupKey: 'inquiry',
          color: const Color(0xFF43A047),
          category: AndroidNotificationCategory.message,
        );
      case 'notice':
      case 'event':
        return _NotificationSpec(
          title: (rawTitle?.trim().isNotEmpty ?? false) ? rawTitle!.trim() : '공지/이벤트',
          body: (rawBody ?? '').toString(),
          groupKey: 'notice',
          color: const Color(0xFFE53935),
          category: AndroidNotificationCategory.promo,
        );
      default:
        if (hasRideStatusLike) {
          final status = (data['status'] ?? data['rideStatus'] ?? '').toString();
          final rideId = (data['rideId'] ?? '').toString();
          final driverName = (data['driverName'] ?? '').toString().trim();
          return _NotificationSpec(
            title: _rideStatusTitle(status),
            body: _rideStatusBody(status, rideId: rideId, driverName: driverName),
            groupKey: 'ride',
            color: const Color(0xFF1A2F7A),
            category: AndroidNotificationCategory.status,
          );
        }
        return _NotificationSpec(
          title: (rawTitle?.trim().isNotEmpty ?? false) ? rawTitle!.trim() : '알림',
          body: (rawBody ?? '').toString(),
          groupKey: 'general',
          color: const Color(0xFF455A64),
          category: AndroidNotificationCategory.message,
        );
    }
  }

  static String _normalizeStatus(String status) {
    final s = status.trim().toLowerCase();
    switch (s) {
      case 'driver_assigned':
        return 'assigned';
      case 'driver_arrived':
      case 'arrived':
      case 'at_pickup':
      case 'pickup_arrived':
        return 'arrived_pickup';
      case 'start':
      case 'in_progress':
      case 'driving':
        return 'on_trip';
      case 'finish':
        return 'completed';
      default:
        return s;
    }
  }

  static String _rideStatusTitle(String status) {
    switch (_normalizeStatus(status)) {
      case 'requested':
      case 'created':
        return '호출 접수 완료';
      case 'matching':
        return '기사님 찾는 중';
      case 'assigned':
      case 'accepted':
        return '기사님 배정 완료';
      case 'arriving':
        return '기사님이 이동 중이에요';
      case 'arrived_pickup':
        return '기사님이 도착했어요';
      case 'picked_up':
      case 'on_trip':
        return '운행이 시작됐어요';
      case 'completed':
        return '운행 완료';
      case 'cancelled':
      case 'canceled':
        return '호출이 취소됐어요';
      default:
        return '배차 상태 업데이트';
    }
  }

  static String _rideStatusBody(String status, {required String rideId, required String driverName}) {
    final s = _normalizeStatus(status);
    final suffix = rideId.isNotEmpty ? ' (번호: $rideId)' : '';
    final who = driverName.isNotEmpty ? '$driverName 기사님이 ' : '기사님이 ';
    switch (s) {
      case 'requested':
      case 'created':
        return '호출이 정상 접수되었습니다.$suffix';
      case 'matching':
        return '가까운 기사님께 배차를 요청하고 있어요.$suffix';
      case 'assigned':
      case 'accepted':
        return '$who배정되었습니다. 출발 준비를 해주세요.$suffix';
      case 'arriving':
        return '$who출발지로 이동 중입니다.$suffix';
      case 'arrived_pickup':
        return '$who출발지에 도착했습니다. 만나서 출발해 주세요.$suffix';
      case 'picked_up':
      case 'on_trip':
        return '운행이 시작되었습니다. 안전 운행하세요.$suffix';
      case 'completed':
        return '운행이 완료되었습니다. 이용해주셔서 감사합니다.$suffix';
      case 'cancelled':
      case 'canceled':
        return '호출이 취소되었습니다.$suffix';
      default:
        return '배차 상태가 변경되었습니다.$suffix';
    }
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  static String _fmtAmount(int n) {
    final digits = n.abs().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return n < 0 ? '-$digits' : '+$digits';
  }

  static String _mileageBody({required int amount, required int balance}) {
    final amountText = '${_fmtAmount(amount)}원';
    final balanceText = '${balance.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}원';
    return '변동: $amountText · 현재 잔액: $balanceText';
  }

  static Future<void> _showLocal(RemoteMessage m) async {
    final spec = _compose(m);
    final payload = jsonEncode(m.data);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelIdDefault,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        category: spec.category,
        groupKey: 'ildd-${spec.groupKey}',
        color: spec.color,
        colorized: true,
        showWhen: true,
        styleInformation: BigTextStyleInformation(
          spec.body,
          contentTitle: spec.title,
        ),
      ),
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      spec.title,
      spec.body,
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
            : (type == 'mileage' || type == 'payment')
                ? '/mileage'
                : (type == 'notice' || type == 'event')
                    ? '/notice'
                    : (type == 'qa' || type == 'inquiry')
                        ? '/qa'
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

class _NotificationSpec {
  const _NotificationSpec({
    required this.title,
    required this.body,
    required this.groupKey,
    required this.color,
    required this.category,
  });

  final String title;
  final String body;
  final String groupKey;
  final Color color;
  final AndroidNotificationCategory category;
}

