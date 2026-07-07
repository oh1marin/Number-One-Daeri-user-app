import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_security_suite/flutter_security_suite.dart';

/// 보안 검사 서비스
/// - Root/Jailbreak 감지
/// - 에뮬레이터 감지
/// - 스크린 녹화 감지
/// - 앱 변조 감지
/// - 스크린샷 방지 (결제 화면 등)
class SecurityService {
  SecurityService._();

  static SecureBankKit? _kit;

  static SecureBankKit get kit {
    _kit ??= SecureBankKit.initialize(
        enableRootDetection: true,
        enableAppIntegrity: true,
        enableEmulatorDetection: true,
        enableScreenRecordingDetection: true,
        enableTamperDetection: true,
        enableRuntimeProtection: true,
        enablePinning: false, // 필요 시 API 호스트 SPKI 해시 설정
        enableLogging: kDebugMode,
        certificatePins: const {},
      );
    return _kit!;
  }

  /// 릴리즈: 루팅·변조·후킹만 차단 (무결성/에뮬레이터 오탐으로 이탈·1점 리뷰 방지)
  static bool shouldBlockApp(SecurityCheckResult result) {
    if (kDebugMode) return !result.secure;
    return result.isRooted || result.isTampered || result.isRuntimeHooked;
  }

  /// 보안 검사 실행. 위협 감지 시 false 반환
  static Future<SecurityCheckResult> runSecurityCheck() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return SecurityCheckResult(secure: true);
    }
    final status = await kit.runSecurityCheck();
    return SecurityCheckResult(
      secure: status.isSecure,
      isRooted: status.isRooted,
      isEmulator: status.isEmulator,
      isScreenBeingRecorded: status.isScreenBeingRecorded,
      isTampered: status.isTampered,
      isRuntimeHooked: status.isRuntimeHooked,
      isAppIntegrityValid: status.isAppIntegrityValid,
    );
  }

  /// 스크린샷/녹화 방지 활성화 (결제 화면 등)
  static Future<void> enableScreenshotProtection() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await kit.screenshotProtection.enable();
  }

  /// 스크린샷/녹화 방지 비활성화
  static Future<void> disableScreenshotProtection() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await kit.screenshotProtection.disable();
  }
}

class SecurityCheckResult {
  const SecurityCheckResult({
    required this.secure,
    this.isRooted = false,
    this.isEmulator = false,
    this.isScreenBeingRecorded = false,
    this.isTampered = false,
    this.isRuntimeHooked = false,
    this.isAppIntegrityValid = true,
  });

  final bool secure;
  final bool isRooted;
  final bool isEmulator;
  final bool isScreenBeingRecorded;
  final bool isTampered;
  final bool isRuntimeHooked;
  final bool isAppIntegrityValid;
}
