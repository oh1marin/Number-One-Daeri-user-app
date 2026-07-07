import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/connectivity_service.dart';

/// 앱 전역 오프라인 배너 + 연결 복구 알림
class ConnectivityBannerScope extends StatefulWidget {
  const ConnectivityBannerScope({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityBannerScope> createState() => _ConnectivityBannerScopeState();
}

class _ConnectivityBannerScopeState extends State<ConnectivityBannerScope> {
  bool _offline = false;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final offline = await ConnectivityService.isOffline;
    if (mounted) setState(() => _offline = offline);
    _sub = ConnectivityService.onOnlineChanged.listen((online) {
      if (!mounted) return;
      final wasOffline = _offline;
      setState(() => _offline = !online);
      if (wasOffline && online) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인터넷에 다시 연결되었습니다.'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  Future<void> _recheck() async {
    final offline = await ConnectivityService.isOffline;
    if (!mounted) return;
    setState(() => _offline = offline);
    if (!offline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('연결되었습니다.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_offline) _OfflineBanner(onRetry: _recheck),
        Expanded(child: widget.child),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFB71C1C),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const PhosphorIcon(
                PhosphorIconsRegular.wifiSlash,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '인터넷 연결이 없습니다. Wi‑Fi 또는 데이터를 확인해 주세요.',
                  style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '다시 확인',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 연결 상태 변화 시 [onReconnect] 호출 (화면별 데이터 재로드용)
class ConnectivityReconnectListener extends StatefulWidget {
  const ConnectivityReconnectListener({
    super.key,
    required this.onReconnect,
    required this.child,
  });

  final VoidCallback onReconnect;
  final Widget child;

  @override
  State<ConnectivityReconnectListener> createState() =>
      _ConnectivityReconnectListenerState();
}

class _ConnectivityReconnectListenerState
    extends State<ConnectivityReconnectListener> {
  StreamSubscription<bool>? _sub;
  bool? _wasOnline;

  @override
  void initState() {
    super.initState();
    ConnectivityService.checkIsOnline().then((online) {
      _wasOnline = online;
    });
    _sub = ConnectivityService.onOnlineChanged.listen((online) {
      if (_wasOnline == false && online) {
        widget.onReconnect();
      }
      _wasOnline = online;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
