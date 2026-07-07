import 'package:flutter/material.dart';
import 'package:snackly/snackly.dart';

import '../services/session_service.dart';

String? _lastSnackKey;
DateTime? _lastSnackAt;

bool _shouldSkipSnack(String title, String message) {
  if (SessionService.isAuthInvalid && _isAuthRelatedSnack(title, message)) {
    return true;
  }

  final key = '$title|$message';
  final now = DateTime.now();
  if (_lastSnackKey == key &&
      _lastSnackAt != null &&
      now.difference(_lastSnackAt!) < const Duration(milliseconds: 1800)) {
    return true;
  }
  _lastSnackKey = key;
  _lastSnackAt = now;
  return false;
}

bool _isAuthRelatedSnack(String title, String message) {
  final combined = '$title $message'.toLowerCase();
  return combined.contains('로그인') ||
      combined.contains('회원가입') ||
      (combined.contains('인증') && combined.contains('만료')) ||
      combined.contains('다시 로그인');
}

void _showSnack({
  required BuildContext context,
  required String title,
  required String message,
  required SnackbarType type,
  required Color backgroundColor,
}) {
  final msg = _oneLine(message);
  if (msg.isEmpty || _shouldSkipSnack(title, msg)) return;

  Snackly.show(
    context: context,
    title: title,
    message: msg,
    type: type,
    style: SnackbarStyle.filled,
    backgroundColor: backgroundColor,
    textColor: Colors.white,
    iconColor: Colors.white,
    fontSize: 12,
    titleFontSize: 13,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    borderRadius: 8,
  );
}

/// 작은 크기, 선명한 색상, 한 줄 메시지
void showSuccessSnackBar(BuildContext context, String message, {String title = '완료'}) {
  _showSnack(
    context: context,
    title: title,
    message: message,
    type: SnackbarType.success,
    backgroundColor: const Color(0xFF2E7D32),
  );
}

void showErrorSnackBar(BuildContext context, String message, {String title = '오류'}) {
  _showSnack(
    context: context,
    title: title,
    message: message,
    type: SnackbarType.error,
    backgroundColor: const Color(0xFFC62828),
  );
}

void showWarningSnackBar(BuildContext context, String message, {String title = '확인'}) {
  _showSnack(
    context: context,
    title: title,
    message: message,
    type: SnackbarType.warning,
    backgroundColor: const Color(0xFFE65100),
  );
}

void showInfoSnackBar(BuildContext context, String message, {String title = '알림'}) {
  _showSnack(
    context: context,
    title: title,
    message: message,
    type: SnackbarType.info,
    backgroundColor: const Color(0xFF1565C0),
  );
}

String _oneLine(String msg) {
  final one = msg.replaceAll('\n', ' ').trim();
  if (one.isEmpty) return '';
  if (one.length <= 28) return one;
  return '${one.substring(0, 28)}...';
}
