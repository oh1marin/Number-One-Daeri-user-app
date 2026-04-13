import '../models/api_response.dart';
import 'api_client.dart';

class DashboardApi {
  static Future<ApiResponse<Map<String, dynamic>>> getDashboard() async {
    final res = await ApiClient.get('/dashboard');
    final map = res.data as Map<String, dynamic>?;
    return ApiResponse.fromJson(
      map ?? {},
      (d) => d is Map<String, dynamic> ? d : <String, dynamic>{},
    );
  }
}
