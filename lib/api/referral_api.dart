import '../models/api_response.dart';
import 'api_client.dart';

/// 추천인 API
class ReferralApi {
  static const _base = '/referrals';

  /// 추천인 등록
  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String referrerPhone,
  }) async {
    final res = await ApiClient.post('$_base/register', {
      'referrerPhone': referrerPhone.replaceAll(RegExp(r'[^\d]'), ''),
    });
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => d as Map<String, dynamic>,
    );
  }

  /// 내 추천인 현황
  static Future<ApiResponse<Map<String, dynamic>>> getMy() async {
    final res = await ApiClient.get('$_base/my');
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => d as Map<String, dynamic>,
    );
  }
}
