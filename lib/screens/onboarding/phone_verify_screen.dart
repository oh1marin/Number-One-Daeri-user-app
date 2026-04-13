import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/auth_api.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';

/// 본인인증 - 전화번호 + OTP (앱 로그인)
class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _sendLoading = false;
  bool _verifyLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 인증 실패 시 짧고 명확한 메시지로 변환 (긴 에러코드 방지)
  String _otpFriendlyError(String? raw) {
    if (raw == null || raw.isEmpty) return '다시 시도해주세요.';
    final lower = raw.toLowerCase();
    if (lower.contains('invalid') || lower.contains('incorrect') || lower.contains('wrong') ||
        lower.contains('만료') || lower.contains('잘못') || lower.contains('expired') ||
        lower.contains('mismatch') || lower.contains('코드') || lower.contains('code')) {
      return '인증번호가 올바르지 않습니다.';
    }
    if (lower.contains('connection') || lower.contains('network') || lower.contains('timeout') ||
        lower.contains('연결')) {
      return '네트워크 연결을 확인해주세요.';
    }
    if (raw.length > 50) return '다시 시도해주세요.';
    return raw;
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.length < 10) {
      showWarningSnackBar(context, '전화번호를 확인해주세요.', title: '확인');
      return;
    }
    if (_sendLoading) return;
    setState(() => _sendLoading = true);
    try {
      final res = await AuthApi.sendPhoneOtp(phone: phone);
      if (res.success && mounted) {
        showSuccessSnackBar(context, '인증번호가 발송되었습니다.', title: '발송 완료');
      } else if (mounted) {
        showErrorSnackBar(context, _otpFriendlyError(res.error));
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, _otpFriendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _sendLoading = false);
    }
  }

  Future<void> _verifyAndSignup() async {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final code = _codeController.text.trim();
    if (phone.length < 10) {
      showWarningSnackBar(context, '전화번호를 확인해주세요.', title: '확인');
      return;
    }
    if (code.length != 6) {
      showWarningSnackBar(context, '인증번호 6자리를 입력해주세요.', title: '확인');
      return;
    }
    if (_verifyLoading) return;
    setState(() => _verifyLoading = true);
    try {
      final res = await AuthApi.verifyPhoneOtp(phone: phone, code: code);
      if (res.success && res.data != null && mounted) {
        final accessToken = res.data!['accessToken'] as String?;
        final refreshToken = res.data!['refreshToken'] as String?;
        if (accessToken != null && refreshToken != null) {
          await AuthService.saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(
              '/referrer',
              arguments: true,
            );
          }
        } else {
          showErrorSnackBar(context, '인증 오류');
        }
      } else if (mounted) {
        showErrorSnackBar(context, _otpFriendlyError(res.error));
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, _otpFriendlyError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _verifyLoading = false);
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
            PhosphorIcon(PhosphorIconsRegular.shieldCheck, color: AppTheme.accentBlue, size: 24),
            const Gap(8),
            const Text('본인인증', style: TextStyle(color: Colors.black87)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SelfVerifyCard(),
            const Gap(24),
            _Step1Section(
              controller: _phoneController,
              loading: _sendLoading,
              onRequest: _requestOtp,
            ),
            const Gap(20),
            _Step2Section(
              controller: _codeController,
              loading: _verifyLoading,
              onVerify: _verifyAndSignup,
            ),
            const Gap(24),
            _InfoBox(),
          ],
        ),
      ),
    );
  }
}

class _SelfVerifyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: Colors.grey.shade300),
              Icon(Icons.lock, size: 36, color: AppTheme.accentYellow),
            ],
          ),
          const Gap(16),
          const Text(
            '본인 인증',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Gap(8),
          Text(
            '서비스 이용을 위해 아래에서 본인인증이 필요합니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Step1Section extends StatelessWidget {
  const _Step1Section({
    required this.controller,
    required this.loading,
    required this.onRequest,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepBadge(step: 1),
            const Gap(12),
            const Text('휴대폰번호 입력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const Gap(12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '010 0000 0000',
            prefixIcon: PhosphorIcon(PhosphorIconsRegular.phone, color: Colors.grey.shade500, size: 22),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: loading ? null : onRequest,
            icon: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt, color: Colors.white, size: 20),
            label: Text(loading ? '발송 중...' : '인증번호 요청'),
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

class _Step2Section extends StatelessWidget {
  const _Step2Section({
    required this.controller,
    required this.loading,
    required this.onVerify,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StepBadge(step: 2),
            const Gap(12),
            const Text('인증번호 입력', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        const Gap(12),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '인증번호 6자리',
            prefixIcon: PhosphorIcon(PhosphorIconsRegular.key, color: Colors.grey.shade500, size: 22),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: loading ? null : onVerify,
            icon: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : PhosphorIcon(PhosphorIconsRegular.check, color: Colors.white, size: 20),
            label: Text(loading ? '확인 중...' : '인증 확인'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: AppTheme.accentBlue,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 22),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '① 휴대폰번호 입력 후 인증번호 요청을 누르세요.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
                const Gap(6),
                Text(
                  '② 문자로 도착한 인증번호를 입력 후 인증 확인을 누르세요.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
