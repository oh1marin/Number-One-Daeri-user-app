import 'package:dio/dio.dart';

String toFriendlyError(Object error, {String fallback = '요청 처리 중 문제가 발생했습니다.'}) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = (data['message'] ?? data['error'])?.toString();
    } else {
      serverMessage = data?.toString();
    }

    if (status == 401) return '로그인이 만료되었습니다. 다시 로그인해 주세요.';
    if (status == 403) return '접근 권한이 없습니다.';
    if (status == 404) return '요청한 정보를 찾을 수 없습니다.';
    if (status != null && status >= 500) return '서버가 불안정합니다. 잠시 후 다시 시도해 주세요.';

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return '네트워크 연결이 원활하지 않습니다. 인터넷 상태를 확인해 주세요.';
    }

    if (serverMessage != null && serverMessage.trim().isNotEmpty) {
      return serverMessage.trim();
    }
  }

  final raw = error.toString().trim();
  if (raw.isEmpty) return fallback;
  if (raw.length > 80) return fallback;
  return raw;
}

String formatKrw(int value) {
  return value.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}

String formatDateShort(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final t = raw.trim();
  try {
    final d = DateTime.parse(t).toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y.$m.$day';
  } catch (_) {
    final match = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(t);
    if (match != null) {
      final y = match.group(1)!;
      final m = match.group(2)!.padLeft(2, '0');
      final d = match.group(3)!.padLeft(2, '0');
      return '$y.$m.$d';
    }
    return t.length > 10 ? t.substring(0, 10) : t;
  }
}

