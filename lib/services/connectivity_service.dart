import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// 네트워크 연결 상태 감지
class ConnectivityService {
  ConnectivityService._();

  static final _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// 현재 연결 상태
  static Future<List<ConnectivityResult>> check() => _connectivity.checkConnectivity();

  /// 오프라인인지
  static Future<bool> get isOffline async {
    final result = await check();
    return result.every((r) => r == ConnectivityResult.none);
  }

  /// 온라인인지 (Wi-Fi, 셀룰러, 이더넷 등)
  static Future<bool> get isOnline async => !await isOffline;

  /// 연결 상태 스트림 구독 (연결 끊김 시 사용자 알림 등)
  static void listen(void Function(List<ConnectivityResult> result) onChanged) {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen(onChanged);
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
