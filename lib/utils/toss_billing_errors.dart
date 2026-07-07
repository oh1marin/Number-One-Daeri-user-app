import 'package:dio/dio.dart';

import '../config/toss_config.dart';

/// 빌링(등록 카드·자동결제) 미계약/미설정 오류인지
bool isTossBillingUnavailable(Object error) {
  return tossBillingErrorMessage(error) != null;
}

/// 빌링 관련 오류 → 계약 안내. 해당 없으면 null.
String? tossBillingErrorMessage(Object error) {
  if (error is! DioException) {
    return _billingMessageFromText(error.toString());
  }

  final status = error.response?.statusCode;
  final data = error.response?.data;
  final path = error.requestOptions.uri.path;

  final isBillingPath = path.contains('/billing') ||
      path.contains('charge-with-card');

  if (status == 503 && isBillingPath) {
    return tossBillingContractRequiredMessage;
  }

  if (data is Map<String, dynamic>) {
    final code = data['code']?.toString();
    if (code == 'NOT_SUPPORTED_METHOD') {
      return tossBillingContractRequiredMessage;
    }
    final combined =
        '${data['message'] ?? ''} ${data['error'] ?? ''}'.toLowerCase();
    final billingHint = _billingMessageFromText(combined);
    if (billingHint != null) return billingHint;
  }

  if (status == 400 || status == 503) {
    return _billingMessageFromText(error.message ?? '');
  }

  return null;
}

String? _billingMessageFromText(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('not_supported_method')) {
    return tossBillingContractRequiredMessage;
  }
  if (lower.contains('자동결제') &&
      (lower.contains('계약') || lower.contains('설정'))) {
    return tossBillingContractRequiredMessage;
  }
  if (lower.contains('toss_api_secret') ||
      lower.contains('toss_api_client') ||
      (lower.contains('빌링') && lower.contains('설정'))) {
    return tossBillingContractRequiredMessage;
  }
  return null;
}
