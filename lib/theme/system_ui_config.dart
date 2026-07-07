import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Android 15 (SDK 35) edge-to-edge — Play Console 권장 조치.
/// 시스템 바 색은 styles.xml·위젯 배경으로 처리, 여기서는 아이콘 밝기만 지정.
class SystemUiConfig {
  SystemUiConfig._();

  /// 라이트 화면용 (흰 AppBar / 회색 Scaffold)
  static const overlayLight = SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  /// 스플래시 등 다크 배경용
  static const overlayDark = SystemUiOverlayStyle(
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  static Future<void> apply() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

/// 다크 배경 화면(스플래시)에서 상태바 아이콘만 밝게.
class SystemUiDarkBackground extends StatelessWidget {
  const SystemUiDarkBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiConfig.overlayDark,
      child: child,
    );
  }
}
