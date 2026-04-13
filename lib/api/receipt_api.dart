import 'package:dio/dio.dart';

import 'api_client.dart';

/// 현금영수증 API
/// POST /receipts/cash  — 현금영수증 발행 요청
/// GET  /receipts/cash  — 발행 내역 조회
class ReceiptApi {
  static const _base = '/receipts/cash';

  /// 현금영수증 발행 요청
  /// [rideId] 운행 ID (선택)
  /// [phoneOrBizNo] 휴대폰번호 또는 사업자번호
  /// [type] 'phone' | 'biz'
  static Future<CashReceiptResult> request({
    String? rideId,
    required String phoneOrBizNo,
    required String type,
    required int amount,
  }) async {
    try {
      final res = await ApiClient.post(_base, {
        if (rideId case final rid?) 'rideId': rid,
        'identifier': phoneOrBizNo,
        'identifierType': type,
        'amount': amount,
      });
      final map = res.data as Map<String, dynamic>?;
      final data = (map?['data'] as Map<String, dynamic>?) ?? map ?? {};
      return CashReceiptResult(
        id: data['id']?.toString() ?? '',
        status: data['status']?.toString() ?? 'pending',
        issuedAt: data['issuedAt']?.toString(),
        downloadUrl: data['downloadUrl']?.toString(),
      );
    } on DioException catch (e) {
      throw Exception('현금영수증 발행 실패 (${e.response?.statusCode})');
    }
  }

  /// 발행 내역 목록 조회
  static Future<List<CashReceiptResult>> getList() async {
    try {
      final res = await ApiClient.get(_base);
      final map = res.data as Map<String, dynamic>?;
      final raw = map?['data'];
      final list = raw is List
          ? raw
          : (raw is Map ? raw['items'] as List? ?? [] : []);
      return list
          .whereType<Map<String, dynamic>>()
          .map(CashReceiptResult.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception('영수증 조회 실패 (${e.response?.statusCode})');
    }
  }
}

class CashReceiptResult {
  const CashReceiptResult({
    required this.id,
    required this.status,
    this.issuedAt,
    this.downloadUrl,
    this.amount,
    this.identifier,
  });

  final String id;
  final String status;       // 'issued' | 'pending' | 'failed'
  final String? issuedAt;
  final String? downloadUrl; // PDF/영수증 다운로드 URL
  final int? amount;
  final String? identifier;

  bool get isIssued => status == 'issued';

  factory CashReceiptResult.fromJson(Map<String, dynamic> j) {
    return CashReceiptResult(
      id: j['id']?.toString() ?? '',
      status: j['status']?.toString() ?? '',
      issuedAt: j['issuedAt']?.toString(),
      downloadUrl: j['downloadUrl']?.toString(),
      amount: (j['amount'] as num?)?.toInt(),
      identifier: j['identifier']?.toString(),
    );
  }
}
