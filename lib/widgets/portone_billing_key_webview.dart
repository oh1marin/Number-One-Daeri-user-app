import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// PortOne requestIssueBillingKey / requestIssueBillingKeyAndPay 전용 WebView
/// - redirect URL의 raw params(billingKey, cardName 등)를 그대로 callback으로 전달
/// - portone_flutter_v2의 PaymentResponse는 billingKey/cardName을 포함하지 않아 이 위젯 사용
class PortoneBillingKeyWebView extends StatefulWidget {
  const PortoneBillingKeyWebView({
    super.key,
    required this.mode,
    required this.onResult,
    required this.onError,
    required this.storeId,
    required this.channelKey,
    required this.appScheme,
    this.paymentId,
    this.orderName,
    this.amount,
    this.initialChild,
    this.useTestChannel = false,
  });

  /// 100원 인증(빌링키만) vs 결제+빌링키
  static const String modeBillingKey = 'billingKey';
  static const String modeBillingKeyAndPay = 'billingKeyAndPay';

  final String mode;
  final void Function(Map<String, dynamic> rawParams) onResult;
  final void Function(Object error) onError;
  final String storeId;
  final String channelKey;
  final String appScheme;
  final String? paymentId;
  final String? orderName;
  final int? amount;
  final Widget? initialChild;
  final bool useTestChannel;

  @override
  State<PortoneBillingKeyWebView> createState() =>
      _PortoneBillingKeyWebViewState();
}

class _PortoneBillingKeyWebViewState extends State<PortoneBillingKeyWebView> {
  int _stackIndex = 0;
  final List<Uri> _redirectedUrls = [];

  String get _redirectUrl => '${widget.appScheme}://complete';

  String _buildHtml() {
    final storeId = jsonEncode(widget.storeId);
    final channelKey = jsonEncode(widget.channelKey);
    final appScheme = jsonEncode(widget.appScheme);
    final redirectUrl = jsonEncode(_redirectUrl);

    if (widget.mode == PortoneBillingKeyWebView.modeBillingKey) {
      // 100원 인증 — 빌링키 발급만 (requestIssueBillingKey)
      final issueId =
          jsonEncode('card-reg-${DateTime.now().millisecondsSinceEpoch}');
      final isTestChannel = widget.useTestChannel;
      return '''
<!doctype html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
<script>
window.addEventListener("flutterInAppWebViewPlatformReady", () => {
  PortOne.requestIssueBillingKey({
    storeId: $storeId,
    channelKey: $channelKey,
    billingKeyMethod: "CARD",
    issueId: $issueId,
    issueName: "카드 등록 인증",
    displayAmount: 100,
    currency: "KRW",
    customer: { customerId: $issueId },
    redirectUrl: $redirectUrl,
    appScheme: $appScheme,
    isTestChannel: $isTestChannel,
  }).then((res) => {
    if (res && res.code) {
      window.flutter_inappwebview.callHandler("portoneError", res.message || "빌링키 발급 실패");
    } else if (res && !res.code) {
      const q = new URLSearchParams(res).toString();
      window.location.href = $redirectUrl + "?" + q;
    }
  }).catch((err) =>
    window.flutter_inappwebview.callHandler("portoneError", err?.message || String(err)));
});
</script>
</head><body></body></html>
''';
    } else {
      // 결제 + 빌링키 발급 (requestIssueBillingKeyAndPay)
      final paymentId = jsonEncode(widget.paymentId ?? '');
      final orderName = jsonEncode(widget.orderName ?? '');
      final amount = widget.amount ?? 0;
      final redirectUrl = jsonEncode(_redirectUrl);
      final isTestChannel = widget.useTestChannel;
      return '''
<!doctype html>
<html><head>
<meta name="viewport" content="width=device-width, initial-scale=1" />
<script src="https://cdn.portone.io/v2/browser-sdk.js"></script>
<script>
window.addEventListener("flutterInAppWebViewPlatformReady", () => {
  PortOne.requestIssueBillingKeyAndPay({
    storeId: $storeId,
    channelKey: $channelKey,
    paymentId: $paymentId,
    orderName: $orderName,
    totalAmount: $amount,
    currency: "KRW",
    billingKeyAndPayMethod: "CARD",
    customer: { customerId: $paymentId },
    redirectUrl: $redirectUrl,
    appScheme: $appScheme,
    isTestChannel: $isTestChannel,
  }).then((res) => {
    if (res && res.code) {
      window.flutter_inappwebview.callHandler("portoneError", res.message || "결제 실패");
    } else if (res && !res.code) {
      const q = new URLSearchParams(res).toString();
      window.location.href = $redirectUrl + "?" + q;
    }
  }).catch((err) =>
    window.flutter_inappwebview.callHandler("portoneError", err?.message || String(err)));
});
</script>
</head><body></body></html>
''';
    }
  }

  void _handleRedirect(Uri uri) {
    final params = uri.queryParameters;
    if (params.isEmpty) return;

    final raw = <String, dynamic>{};
    for (final e in params.entries) {
      raw[e.key] = e.value;
    }

    final code = raw['code'];
    if (code != null && code.toString().isNotEmpty) {
      widget.onError(Exception(raw['message'] ?? '실패'));
      return;
    }

    widget.onResult(raw);
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
                  Text('로딩 중...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
        InAppWebView(
          initialSettings: InAppWebViewSettings(
            javaScriptCanOpenWindowsAutomatically: true,
            allowsLinkPreview: false,
            useShouldOverrideUrlLoading: true,
            resourceCustomSchemes: [widget.appScheme],
          ),
          onWebViewCreated: (c) async {
            c.addJavaScriptHandler(
              handlerName: 'portoneError',
              callback: (args) {
                widget.onError(Exception(args.isNotEmpty ? args[0] : '오류'));
              },
            );
            await c.loadData(
              mimeType: 'text/html',
              data: _buildHtml(),
              baseUrl: WebUri('https://flutter-sdk-content.portone.io/'),
            );
          },
          onLoadStop: (controller, url) {
            if (mounted) setState(() => _stackIndex = 1);
          },
          shouldOverrideUrlLoading: (_, action) async {
            final url = action.request.url;
            if (url == null) return NavigationActionPolicy.CANCEL;

            final uri = url.uriValue;
            _redirectedUrls.add(uri);

            if (uri.scheme == widget.appScheme) {
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
