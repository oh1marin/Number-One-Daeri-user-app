import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _keyUseBiometricForAppPayment = 'use_biometric_for_app_payment';

/// 앱결제용 생체인증(지문/얼굴) 서비스
/// - 첫 결제 후 "다음부터 인증 사용" 선택 시에만 적용
class BiometricPaymentService {
  BiometricPaymentService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  /// 기기가 생체인증을 지원하는지
  static Future<bool> get isSupported async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// 사용자가 "다음 결제부터 인증 사용"을 켰는지 (첫 PG 결제 후 물어봄)
  static Future<bool> get useBiometricForAppPayment async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseBiometricForAppPayment) ?? false;
  }

  static Future<void> setUseBiometricForAppPayment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseBiometricForAppPayment, value);
  }

  /// 사용 가능한 생체인증 종류 (지문, 얼굴 등)
  static Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// 생체인증 실행. 성공 시 true, 실패/취소 시 false
  static Future<bool> authenticate({
    String reason = '결제를 진행하려면 인증이 필요합니다',
    bool useErrorDialogs = true,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return true;

      final available = await _auth.getAvailableBiometrics();
      if (available.isEmpty) return true;

      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('BiometricPaymentService.authenticate: $e');
      return false;
    }
  }

  /// 사용자에게 보여줄 생체인증 종류 설명 (예: "지문 또는 Face ID")
  static Future<String> get biometricTypeName async {
    final types = await availableBiometrics;
    if (types.isEmpty) return '생체인증';
    if (types.contains(BiometricType.face)) {
      return types.contains(BiometricType.fingerprint) ? '지문 또는 Face ID' : 'Face ID';
    }
    if (types.contains(BiometricType.fingerprint)) return '지문';
    return '생체인증';
  }
}
