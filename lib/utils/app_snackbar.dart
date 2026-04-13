import 'package:flutter/material.dart';
import 'package:snackly/snackly.dart';

/// 작은 크기, 선명한 색상, 한 줄 메시지
void showSuccessSnackBar(BuildContext context, String message, {String title = '완료'}) {
  Snackly.show(
    context: context,
    title: title,
    message: _oneLine(message),
    type: SnackbarType.success,
    style: SnackbarStyle.filled,
    backgroundColor: const Color(0xFF2E7D32),
    textColor: Colors.white,
    iconColor: Colors.white,
    fontSize: 12,
    titleFontSize: 13,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    borderRadius: 8,
  );
}

void showErrorSnackBar(BuildContext context, String message, {String title = '오류'}) {
  Snackly.show(
    context: context,
    title: title,
    message: _oneLine(message),
    type: SnackbarType.error,
    style: SnackbarStyle.filled,
    backgroundColor: const Color(0xFFC62828),
    textColor: Colors.white,
    iconColor: Colors.white,
    fontSize: 12,
    titleFontSize: 13,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    borderRadius: 8,
  );
}

void showWarningSnackBar(BuildContext context, String message, {String title = '확인'}) {
  Snackly.show(
    context: context,
    title: title,
    message: _oneLine(message),
    type: SnackbarType.warning,
    style: SnackbarStyle.filled,
    backgroundColor: const Color(0xFFE65100),
    textColor: Colors.white,
    iconColor: Colors.white,
    fontSize: 12,
    titleFontSize: 13,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    borderRadius: 8,
  );
}

void showInfoSnackBar(BuildContext context, String message, {String title = '알림'}) {
  Snackly.show(
    context: context,
    title: title,
    message: _oneLine(message),
    type: SnackbarType.info,
    style: SnackbarStyle.filled,
    backgroundColor: const Color(0xFF1565C0),
    textColor: Colors.white,
    iconColor: Colors.white,
    fontSize: 12,
    titleFontSize: 13,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    borderRadius: 8,
  );
}

String _oneLine(String msg) {
  final one = msg.replaceAll('\n', ' ').trim();
  if (one.length <= 28) return one;
  return '${one.substring(0, 28)}...';
}
