import 'package:dio/dio.dart';

import '../utils/idempotency.dart';
import 'api_client.dart';

/// 토스페이먼츠 직연동 — prepare / confirm (서버 승인)
class TossPaymentsApi {
  static const _base = '/payments/toss';
  static const _timeout = Duration(seconds: 45);

  static String prepareIdempotencyKeyForRide(String rideId) => 'toss-prepare-$rideId';

  /// GET /payments/toss/billing/config — 카드 등록(빌링)용 ck + customerKey
  static Future<TossBillingConfig> fetchBillingConfig() async {
    try {
      final res = await ApiClient.get('$_base/billing/config');
      final map = res.data as Map<String, dynamic>?;
      if (map?['success'] != true) {
        throw _apiException(map, '카드 등록 설정을 불러오지 못했습니다.');
      }
      final data = map!['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('카드 등록 설정 응답이 올바르지 않습니다.');
      }
      return TossBillingConfig.fromJson(data);
    } on DioException catch (e) {
      throw _dioException(e, '카드 등록 설정을 불러오지 못했습니다.');
    }
  }

  /// POST /payments/toss/billing/issue — authKey → billingKey
  static Future<TossBillingIssueData> issueBillingKey({
    required String authKey,
    String? idempotencyKey,
  }) async {
    try {
      final res = await ApiClient.postWithHeaders(
        '$_base/billing/issue',
        data: {'authKey': authKey},
        headers: {
          'Idempotency-Key': idempotencyKey ?? generateIdempotencyKey(),
        },
        sendTimeout: _timeout,
        receiveTimeout: _timeout,
      );
      final map = res.data as Map<String, dynamic>?;
      if (map?['success'] != true) {
        throw _apiException(map, '빌링키 발급에 실패했습니다.');
      }
      final data = map!['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('빌링키 발급 응답이 올바르지 않습니다.');
      }
      return TossBillingIssueData.fromJson(data);
    } on DioException catch (e) {
      throw _dioException(e, '빌링키 발급에 실패했습니다.');
    }
  }

  /// GET /payments/toss/config
  static Future<String?> fetchClientKey() async {
    final res = await ApiClient.get('$_base/config');
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map;
    final key = data?['clientKey']?.toString().trim();
    return key != null && key.isNotEmpty ? key : null;
  }

  /// POST /payments/toss/prepare
  static Future<TossPrepareData> prepare({
    required String rideId,
    required int amount,
    String? idempotencyKey,
  }) async {
    try {
      final res = await ApiClient.postWithHeaders(
      '$_base/prepare',
      data: {
        'rideId': rideId,
        'amount': amount,
      },
      headers: {
        'Idempotency-Key': idempotencyKey ?? prepareIdempotencyKeyForRide(rideId),
      },
      sendTimeout: _timeout,
      receiveTimeout: _timeout,
    );
    final map = res.data as Map<String, dynamic>?;
    if (map?['success'] != true) {
      throw _apiException(map, '결제 준비에 실패했습니다.');
    }
    final data = map!['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('결제 준비 응답이 올바르지 않습니다.');
    return TossPrepareData.fromJson(data);
    } on DioException catch (e) {
      throw _dioException(e, '결제 준비에 실패했습니다.');
    }
  }

  /// POST /payments/toss/confirm — 위젯 인증 후 서버 승인
  static Future<Map<String, dynamic>> confirm({
    required String paymentKey,
    required String orderId,
    required int amount,
    String? idempotencyKey,
  }) async {
    try {
      final res = await ApiClient.postWithHeaders(
      '$_base/confirm',
      data: {
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      },
      headers: {
        'Idempotency-Key': idempotencyKey ?? generateIdempotencyKey(),
      },
      sendTimeout: _timeout,
      receiveTimeout: _timeout,
    );
    final map = res.data as Map<String, dynamic>?;
    if (map?['success'] != true) {
      throw _apiException(map, '결제 승인에 실패했습니다.');
    }
    final data = map!['data'] as Map<String, dynamic>? ?? {};
    return Map<String, dynamic>.from(data);
    } on DioException catch (e) {
      throw _dioException(e, '결제 승인에 실패했습니다.');
    }
  }

  static Exception _dioException(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return _apiException(data, fallback);
    }
    return Exception(fallback);
  }

  static Exception _apiException(Map<String, dynamic>? map, String fallback) {
    final message = map?['message'] ?? map?['error'] ?? fallback;
    final code = map?['code']?.toString();
    if (code != null && code.isNotEmpty) {
      return Exception('$message (code: $code)');
    }
    return Exception(message.toString());
  }
}

class TossBillingConfig {
  const TossBillingConfig({
    required this.clientKey,
    required this.customerKey,
  });

  final String clientKey;
  final String customerKey;

  factory TossBillingConfig.fromJson(Map<String, dynamic> json) {
    return TossBillingConfig(
      clientKey: json['clientKey']?.toString() ?? '',
      customerKey: json['customerKey']?.toString() ?? '',
    );
  }
}

class TossBillingIssueData {
  const TossBillingIssueData({
    required this.billingKey,
    required this.cardName,
  });

  final String billingKey;
  final String cardName;

  factory TossBillingIssueData.fromJson(Map<String, dynamic> json) {
    return TossBillingIssueData(
      billingKey: json['billingKey']?.toString() ?? '',
      cardName: json['cardName']?.toString() ?? '등록카드',
    );
  }
}

class TossPrepareData {
  const TossPrepareData({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.orderName,
    this.clientKey,
  });

  final String paymentId;
  final String orderId;
  final int amount;
  final String orderName;
  final String? clientKey;

  factory TossPrepareData.fromJson(Map<String, dynamic> json) {
    return TossPrepareData(
      paymentId: json['paymentId']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      orderName: json['orderName']?.toString() ?? '대리운전 이용료',
      clientKey: json['clientKey']?.toString(),
    );
  }
}
