import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../config/toss_config.dart';

/// 토스 자동결제(빌링) 카드 등록 — requestBillingAuth → authKey
class TossBillingAuthWebView extends StatefulWidget {
  const TossBillingAuthWebView({
    super.key,
    required this.clientKey,
    required this.customerKey,
    required this.onAuthKey,
    required this.onError,
    this.initialChild,
    this.loadTimeout = const Duration(seconds: 45),
  });

  final String clientKey;
  final String customerKey;
  final void Function(String authKey) onAuthKey;
  final void Function(Object error) onError;
  final Widget? initialChild;
  final Duration loadTimeout;

  @override
  State<TossBillingAuthWebView> createState() => _TossBillingAuthWebViewState();
}

class _TossBillingAuthWebViewState extends State<TossBillingAuthWebView> {
  int _stackIndex = 0;
  bool _completed = false;
  Timer? _loadTimeoutTimer;

  static const _successUrl = '$tossAppSchemeHost://toss/billing/success';
  static const _failUrl = '$tossAppSchemeHost://toss/billing/fail';

  static const _sdkHead = '''
<link rel="preconnect" href="https://js.tosspayments.com" crossorigin />
<script src="https://js.tosspayments.com/v2/standard"></script>
''';

  String _sdkBootstrap(String invokeJs) => '''
(function() {
  var started = false;
  function fail(msg) {
    if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler("tossBillingError", msg);
    }
  }
  function start() {
    if (started || !window.TossPayments) return;
    started = true;
    $invokeJs
  }
  function tryStart() {
    if (window.TossPayments && window.flutter_inappwebview) start();
  }
  window.addEventListener("flutterInAppWebViewPlatformReady", tryStart);
  if (window.flutter_inappwebview) tryStart();
  var attempts = 0;
  var timer = setInterval(function() {
    attempts++;
    tryStart();
    if (started || attempts > 200) clearInterval(timer);
  }, 50);
})();
''';

  String _buildHtml() {
    final clientKey = jsonEncode(widget.clientKey);
    final customerKey = jsonEncode(widget.customerKey);
    final successUrl = jsonEncode(_successUrl);
    final failUrl = jsonEncode(_failUrl);
    final appScheme = jsonEncode(tossAppScheme);

    final invoke = '''
(async function() {
  try {
    const tossPayments = TossPayments($clientKey);
    const payment = tossPayments.payment({ customerKey: $customerKey });
    await payment.requestBillingAuth({
      method: "CARD",
      successUrl: $successUrl,
      failUrl: $failUrl,
      appScheme: $appScheme,
    });
  } catch (err) {
    fail(err && err.message ? err.message : String(err));
  }
})();
''';

    return '''
<!doctype html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1" />
$_sdkHead
<script>${_sdkBootstrap(invoke)}</script>
</head><body></body></html>
''';
  }

  @override
  void initState() {
    super.initState();
    _loadTimeoutTimer = Timer(widget.loadTimeout, () {
      if (_completed || !mounted) return;
      _completed = true;
      widget.onError(
        Exception('카드 등록창 로딩 시간이 초과되었습니다. 네트워크를 확인해 주세요.'),
      );
    });
  }

  @override
  void dispose() {
    _loadTimeoutTimer?.cancel();
    super.dispose();
  }

  void _finishSuccess(String authKey) {
    if (_completed) return;
    _completed = true;
    _loadTimeoutTimer?.cancel();
    widget.onAuthKey(authKey);
  }

  void _finishError(Object error) {
    if (_completed) return;
    _completed = true;
    _loadTimeoutTimer?.cancel();
    widget.onError(error);
  }

  void _handleRedirect(Uri uri) {
    if (uri.host == 'toss' && uri.pathSegments.isNotEmpty) {
      final action = uri.pathSegments.first;
      if (action == 'fail') {
        final code = uri.queryParameters['code'];
        final message = uri.queryParameters['message'] ?? '카드 등록에 실패했습니다.';
        if (code == 'PAY_PROCESS_CANCELED') {
          _finishError(Exception('카드 등록이 취소되었습니다.'));
        } else {
          _finishError(Exception(message));
        }
        return;
      }
    }

    final authKey = uri.queryParameters['authKey']?.trim();
    if (authKey != null && authKey.isNotEmpty) {
      _finishSuccess(authKey);
      return;
    }

    final code = uri.queryParameters['code'];
    if (code != null && code.isNotEmpty) {
      _finishError(Exception(uri.queryParameters['message'] ?? '카드 등록에 실패했습니다.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _stackIndex,
      children: [
        widget.initialChild ??
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('카드 등록창 불러오는 중...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptCanOpenWindowsAutomatically: true,
            allowsLinkPreview: false,
            useShouldOverrideUrlLoading: true,
            resourceCustomSchemes: [tossAppSchemeHost],
            cacheEnabled: true,
            domStorageEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          onWebViewCreated: (c) async {
            c.addJavaScriptHandler(
              handlerName: 'tossBillingError',
              callback: (args) {
                _finishError(
                  Exception(args.isNotEmpty ? args[0] : '카드 등록 오류'),
                );
              },
            );
            await c.loadData(
              mimeType: 'text/html',
              data: _buildHtml(),
              baseUrl: WebUri('https://js.tosspayments.com/'),
            );
          },
          onLoadStop: (controller, url) {
            if (mounted) setState(() => _stackIndex = 1);
          },
          shouldOverrideUrlLoading: (_, action) async {
            final url = action.request.url;
            if (url == null) return NavigationActionPolicy.CANCEL;

            final uri = url.uriValue;

            if (uri.scheme == tossAppSchemeHost) {
              _handleRedirect(uri);
              return NavigationActionPolicy.CANCEL;
            }
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationActionPolicy.ALLOW;
            }
            return NavigationActionPolicy.CANCEL;
          },
        ),
      ],
    );
  }
}
