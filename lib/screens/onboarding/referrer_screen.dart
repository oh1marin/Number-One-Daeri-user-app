import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/referral_api.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/friend_referral_background.dart';

/// 내추천인 등록 - 앱 메뉴에서 사용
class ReferrerScreen extends StatefulWidget {
  const ReferrerScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  State<ReferrerScreen> createState() => _ReferrerScreenState();
}

class _ReferrerScreenState extends State<ReferrerScreen> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goNext() async {
    await OnboardingService.setReferrerDone();
    await OnboardingService.setOnboardingComplete();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (route) => false,
      );
    }
  }

  Future<void> _registerReferrer() async {
    final phone = _controller.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.length < 10) {
      showWarningSnackBar(context, '전화번호를 확인해주세요.', title: '확인');
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final res = await ReferralApi.register(referrerPhone: phone);
      if (res.success && mounted) {
        showSuccessSnackBar(context, '추천인 등록이 완료되었습니다.', title: '등록 완료');
        if (widget.isOnboarding) await _goNext();
      } else if (mounted) {
        showErrorSnackBar(context, res.error ?? '등록 실패');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, '등록 실패');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Row(
          children: [
            PhosphorIcon(PhosphorIconsRegular.userPlus, color: AppTheme.accentBlue, size: 24),
            const Gap(8),
            const Text('내추천인 등록', style: TextStyle(color: Colors.black87)),
          ],
        ),
        actions: widget.isOnboarding
            ? [
                TextButton(
                  onPressed: _goNext,
                  child: Text('다음 >', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(),
            const Gap(24),
            _BidirectionalBenefitCard(),
            const Gap(24),
            _InputSection(controller: _controller, loading: _loading, onRegister: _registerReferrer),
            const Gap(20),
            _InfoBox(),
          ],
        ),
      ),
      bottomNavigationBar: widget.isOnboarding
          ? Container(
              color: AppTheme.accentBlue,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: TextButton(
                  onPressed: _goNext,
                  child: const Center(
                    child: Text('건너뛰기 >', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

/// 히어로 영역 - 큰 금액 강조
class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FriendReferralBackgroundCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 16,
      imageAlignment: Alignment.centerRight,
      gradient: LinearGradient(
        colors: [
          AppTheme.accentBlue.withValues(alpha: 0.55),
          AppTheme.lightBlue.withValues(alpha: 0.30),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.accentBlue.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        children: [
          Text(
            '나를 추천해 준 분',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.98),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(8),
          const Text(
            '추천인 등록',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          Text(
            '가입 후 언제든 1명만 등록',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 양방향 혜택 카드 (추천받은 사람 / 나를 추천해준 분)
class _BidirectionalBenefitCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FriendReferralBackgroundCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Row(
        children: [
          Expanded(
            child: _BenefitPill(
              label: '가입 보너스',
              amount: '10,000P',
              sub: '대리 전용·추천 무관',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: PhosphorIcon(PhosphorIconsRegular.arrowsLeftRight, color: Colors.grey.shade500, size: 20),
          ),
          Expanded(
            child: _BenefitPill(
              label: '나를 추천해 준 분',
              amount: '2,000원',
              sub: '친구 등록 시',
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill({required this.label, required this.amount, required this.sub});

  final String label;
  final String amount;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightBlue.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: AppTheme.primaryDark.withValues(alpha: 0.75), fontSize: 13, fontWeight: FontWeight.w600)),
          const Gap(4),
          Text(
            amount,
            style: const TextStyle(
              color: AppTheme.accentBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(2),
          Text(sub, style: TextStyle(color: AppTheme.primaryDark.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.controller,
    required this.loading,
    required this.onRegister,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PhosphorIcon(PhosphorIconsRegular.phone, color: AppTheme.accentBlue, size: 20),
            const Gap(8),
            const Text('나를 추천해 준 분의 전화번호', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const Gap(8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '010 0000 0000',
            prefixIcon: PhosphorIcon(PhosphorIconsRegular.phone, color: Colors.grey.shade500, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const Gap(16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: loading ? null : onRegister,
            icon: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt, color: Colors.white, size: 20),
            label: Text(loading ? '등록 중...' : '추천인 등록하기'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: Colors.amber.shade700, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhosphorIcon(PhosphorIconsRegular.lightbulb, color: Colors.amber.shade700, size: 22),
          const Gap(12),
          const Expanded(
            child: Text(
              '나를 추천해 준 분의 전화번호를 입력하세요.\n'
              '가입 10,000P는 추천과 무관하며 대리 호출에만 사용됩니다.\n'
              '추천인 등록은 가입 후 기한 없이 1명만 가능합니다.',
              style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
