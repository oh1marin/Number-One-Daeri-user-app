import 'package:flutter/material.dart';

import '../config/payment_config.dart';

/// 결제 비활성 시 `false`. 활성 시 `true`.
Future<bool> ensurePaymentAvailable(BuildContext context) async {
  if (paymentFeatureEnabled) return true;
  await showPaymentUnsupportedDialog(context);
  return false;
}

Future<void> showPaymentUnsupportedDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      content: Text(
        paymentUnsupportedMessage,
        style: const TextStyle(fontSize: 15, height: 1.4),
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}
