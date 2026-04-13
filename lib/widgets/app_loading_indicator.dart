import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../theme/app_theme.dart';

/// 대리운전 앱용 로딩 인디케이터 - 차분하고 신뢰감 있는 스타일
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.size = 40.0});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SpinKitFadingCircle(
      color: AppTheme.accentBlue,
      size: size,
    );
  }
}
