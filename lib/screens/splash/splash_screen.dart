import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // 애니메이션(2.4s)과 온보딩 체크를 동시에 실행, 둘 다 끝나야 이동
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2400)),
      OnboardingService.isOnboardingComplete(),
    ]);

    if (!mounted) return;

    final isComplete = results[1] as bool;
    Navigator.pushReplacementNamed(context, isComplete ? '/home' : '/permission');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // 배경 그라데이션
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryDark,
                    const Color(0xFF1A2F6B),
                    const Color(0xFF0A1535),
                  ],
                ),
              ),
            ),
          ),

          // 중앙 메인 콘텐츠
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 로고 아이콘
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.directions_car_rounded,
                        color: AppTheme.primaryDark,
                        size: 52,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.4, 0.4),
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // 앱 이름
                const Text(
                  '일등대리',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),

                const SizedBox(height: 10),

                // 전화번호
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentYellow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    '1668-0001',
                    style: TextStyle(
                      color: AppTheme.accentYellow,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                )
                    .animate(delay: 550.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOut),

                const SizedBox(height: 6),

                // 슬로건
                Text(
                  '24시간 대리운전 서비스',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                )
                    .animate(delay: 700.ms)
                    .fadeIn(duration: 500.ms),
              ],
            ),
          ),

          // 하단 로딩 인디케이터
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _PulsingDots(),
                const SizedBox(height: 16),
                Text(
                  '잠시만 기다려 주세요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 12,
                  ),
                )
                    .animate(delay: 900.ms)
                    .fadeIn(duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 튀어오르는 점 3개 로딩 인디케이터 ─────────────────────────────────────────

class _PulsingDots extends StatefulWidget {
  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctls = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims = _ctls
        .map((c) => Tween<double>(begin: 0, end: -10).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: 900 + i * 160), () {
        if (mounted) _ctls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
