import 'api_client.dart';

/// 출금 신청 API
/// POST /withdrawals
class WithdrawalApi {
  static const _path = '/withdrawals';

  static Future<WithdrawalResult> request({
    required int amount,
    required String bankCode,
    required String accountNumber,
    required String accountHolder,
  }) async {
    final res = await ApiClient.post(_path, {
      'amount': amount,
      'bankCode': bankCode,
      'accountNumber': accountNumber,
      'accountHolder': accountHolder,
    });
    final map = res.data as Map<String, dynamic>?;
    final data = map?['data'] as Map<String, dynamic>? ?? map ?? {};
    return WithdrawalResult(
      id: data['id']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      requestedAt: data['requestedAt']?.toString(),
    );
  }
}

class WithdrawalResult {
  const WithdrawalResult({
    required this.id,
    required this.status,
    this.requestedAt,
  });

  final String id;
  final String status;
  final String? requestedAt;
}
