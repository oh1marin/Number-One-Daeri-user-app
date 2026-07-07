import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// 네트워크 연결 상태 감지
class ConnectivityService {
  ConnectivityService._();

  static final _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static final _onlineController = StreamController<bool>.broadcast();
  static bool? _lastOnline;

  /// `true` = 온라인, `false` = 오프라인 (상태가 바뀔 때만 emit)
  static Stream<bool> get onOnlineChanged {
    _ensureGlobalListen();
    return _onlineController.stream;
  }

  /// 현재 연결 상태
  static Future<List<ConnectivityResult>> check() => _connectivity.checkConnectivity();

  static bool _isOfflineResult(List<ConnectivityResult> result) =>
      result.every((r) => r == ConnectivityResult.none);

  /// 오프라인인지
  static Future<bool> get isOffline async {
    final result = await check();
    return _isOfflineResult(result);
  }

  /// 온라인인지 (Wi-Fi, 셀룰러, 이더넷 등)
  static Future<bool> get isOnline async => !await isOffline;

  static Future<bool> checkIsOnline() async => !await isOffline;

  static void _emitIfChanged(bool online) {
    if (_lastOnline == online) return;
    _lastOnline = online;
    if (!_onlineController.isClosed) {
      _onlineController.add(online);
    }
  }

  static void _ensureGlobalListen() {
    if (_subscription != null) return;
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _emitIfChanged(!_isOfflineResult(results));
    });
    checkIsOnline().then(_emitIfChanged);
  }

  /// 연결 상태 스트림 구독 (전역 [onOnlineChanged]와 별도 콜백)
  static StreamSubscription<List<ConnectivityResult>> listen(
    void Function(List<ConnectivityResult> result) onChanged,
  ) {
    _ensureGlobalListen();
    return _connectivity.onConnectivityChanged.listen(onChanged);
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _lastOnline = null;
  }
}
