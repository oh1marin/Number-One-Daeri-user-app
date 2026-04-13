import 'admin.dart';

class AuthResponse {
  final Admin admin;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.admin,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        admin: Admin.fromJson(json['admin'] as Map<String, dynamic>),
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}
