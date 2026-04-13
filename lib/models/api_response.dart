/// API 공통 응답 포맷
/// 성공: { "success": true, "data": { ... } }
/// 실패: { "success": false, "error": "에러 메시지" }
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) =>
      ApiResponse(
        success: json['success'] as bool? ?? false,
        data: json['data'] != null && fromJsonT != null
            ? fromJsonT(json['data'])
            : json['data'] as T?,
        error: json['error'] as String?,
      );
}
