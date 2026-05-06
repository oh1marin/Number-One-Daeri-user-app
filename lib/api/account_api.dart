import 'dart:async';

import 'api_client.dart';
import 'package:dio/dio.dart';

/// Account lifecycle endpoints for the user app.
class AccountApi {
  AccountApi._();

  /// Delete current user account on backend.
  ///
  /// Backend should implement one of:
  /// - DELETE /users/me  (recommended)
  /// - POST /account/delete (fallback)
  static Future<void> deleteMe() async {
    // Primary (recommended)
    try {
      await ApiClient.delete('/users/me').timeout(const Duration(seconds: 10));
      return;
    } on DioException catch (e) {
      // Fallback only when the route doesn't exist.
      final status = e.response?.statusCode;
      if (status != 404) rethrow;
      await ApiClient.post('/account/delete', {})
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      rethrow;
    }
  }
}

