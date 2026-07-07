import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/app_error_fallback.dart';

/// Play 품질 지수(크래시·ANR·안정성) 개선용 부트스트랩.
class AppQualityService {
  AppQualityService._();

  static bool _crashlyticsReady = false;

  /// [runAppCallback] 안에서 dotenv·API·runApp 등을 실행합니다.
  static Future<void> bootstrap(Future<void> Function() runAppCallback) async {
    WidgetsFlutterBinding.ensureInitialized();
    _tuneImageCache();
    await _installErrorHandlers();

    await runZonedGuarded(
      runAppCallback,
      (error, stack) => _recordError(error, stack, fatal: true),
    );
  }

  static void _tuneImageCache() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = 200;
    cache.maximumSizeBytes = 100 << 20;
  }

  static Future<void> _installErrorHandlers() async {
    await _initCrashlytics();

    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      _recordError(
        details.exception,
        details.stack ?? StackTrace.current,
        fatal: false,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _recordError(error, stack, fatal: true);
      return true;
    };

    if (kReleaseMode) {
      ErrorWidget.builder = (details) => AppErrorFallback(details: details);
    }
  }

  static Future<void> _initCrashlytics() async {
    if (kDebugMode) return;
    try {
      await Firebase.initializeApp();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      _crashlyticsReady = true;
    } catch (_) {
      _crashlyticsReady = false;
    }
  }

  static void _recordError(
    Object error,
    StackTrace stack, {
    required bool fatal,
  }) {
    if (kDebugMode) {
      debugPrint('[AppQuality] ${fatal ? 'FATAL' : 'ERROR'}: $error');
      return;
    }
    if (!_crashlyticsReady) return;
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: fatal,
      ),
    );
  }

  /// 비치명 UI/네트워크 오류 등 — 크래시율 왜곡 방지용.
  static void logNonFatal(Object error, [StackTrace? stack]) {
    _recordError(error, stack ?? StackTrace.current, fatal: false);
  }
}
