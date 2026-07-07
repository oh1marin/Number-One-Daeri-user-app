import 'package:flutter/material.dart';

/// 결제 WebView 공통 래퍼 — 뒤로가기 시 취소 결과 반환, 에러 시 화면 닫기
class PortonePaymentShell extends StatelessWidget {
  const PortonePaymentShell({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final Widget body;

  void _popCancelled(BuildContext context) {
    if (!context.mounted) return;
    Navigator.pop(context, const {'success': false, 'cancelled': true});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popCancelled(context);
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          title: Text(title, style: const TextStyle(color: Colors.black87)),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _popCancelled(context),
          ),
        ),
        body: body,
      ),
    );
  }

  /// PaymentScreen / WebView에서 공통 에러 처리
  static void handlePaymentError(
    BuildContext context,
    Object error, {
    required String Function(Object) messageFor,
  }) {
    final message = messageFor(error);
    debugPrint('결제 오류: $error');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    Navigator.pop(context, {
      'success': false,
      'cancelled': false,
      'message': message,
    });
  }
}
