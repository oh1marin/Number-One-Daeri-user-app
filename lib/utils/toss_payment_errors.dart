import 'package:dio/dio.dart';

import '../config/toss_config.dart';
import 'toss_billing_errors.dart';
import 'user_friendly_text.dart';

/// 토스페이먼츠 API/위젯 오류 코드 → 사용자 안내
String tossPaymentErrorMessage(
  Object error, {
  String fallback = '결제에 실패했습니다. 잠시 후 다시 시도해 주세요.',
}) {
  final billing = tossBillingErrorMessage(error);
  if (billing != null) return billing;

  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final code = data['code']?.toString();
      final mapped = _mapTossCode(code);
      if (mapped != null) return mapped;

      final msg = (data['message'] ?? data['error'])?.toString().trim();
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return loadErrorMessage(error, fallback: fallback);
  }

  final raw = error.toString().trim();
  final lower = raw.toLowerCase();

  if (lower.contains('not_supported_method') || raw.contains('NOT_SUPPORTED_METHOD')) {
    return tossBillingContractRequiredMessage;
  }
  if (lower.contains('unauthorized') || raw.contains('인증')) {
    return '결제 API 인증에 실패했습니다. 서버 토스 API 키(test_ck_/test_sk_) 설정을 확인해 주세요.';
  }
  if (lower.contains('gck') || raw.contains('결제위젯')) {
    return tossWidgetKeySetupMessage();
  }
  if (lower.contains('client') && lower.contains('key')) {
    return tossWidgetKeySetupMessage();
  }
  if (lower.contains('cancel') || raw.contains('취소')) {
    return '결제가 취소되었습니다.';
  }

  final messageOnly = raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
  if (messageOnly.isNotEmpty &&
      messageOnly.length <= 120 &&
      !messageOnly.contains('Instance of')) {
    return messageOnly;
  }

  return fallback;
}

String? _mapTossCode(String? code) {
  if (code == null || code.isEmpty) return null;
  switch (code) {
    case 'UNAUTHORIZED_KEY':
    case 'INVALID_API_KEY':
      return '토스 API 키 인증에 실패했습니다. 결제위젯 승인에는 test_gsk_(위젯 시크릿)가 필요합니다. test_sk_는 결제창용입니다.';
    case 'INVALID_CLIENT_KEY':
    case 'INVALID_WIDGET_CLIENT_KEY':
      return '결제위젯 연동 키가 올바르지 않습니다. test_gck_ / live_gck_ 키를 사용해 주세요.';
    case 'FORBIDDEN_REQUEST':
      return '허용되지 않은 결제 요청입니다. 키 종류(테스트/라이브)와 결제 금액을 확인해 주세요.';
    case 'NOT_FOUND_PAYMENT':
      return '결제 정보를 찾을 수 없습니다. 처음부터 다시 결제해 주세요.';
    case 'ALREADY_PROCESSED_PAYMENT':
      return '이미 처리된 결제입니다.';
    case 'PROVIDER_ERROR':
      return '결제사 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.';
    case 'EXCEED_MAX_CARD_INSTALLMENT_PLAN':
      return '카드 할부 한도를 초과했습니다.';
    case 'INVALID_IDEMPOTENCY_KEY':
      return '결제 요청이 중복되었습니다. 잠시 후 다시 시도해 주세요.';
    case 'IDEMPOTENT_REQUEST_PROCESSING':
      return '이전 결제 요청을 처리 중입니다. 잠시 후 다시 시도해 주세요.';
    case 'NOT_SUPPORTED_METHOD':
      return tossBillingContractRequiredMessage;
    case 'USER_CANCEL':
    case 'PAY_PROCESS_CANCELED':
      return '결제가 취소되었습니다.';
    default:
      return null;
  }
}
