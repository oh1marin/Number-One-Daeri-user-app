import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/complaints_api.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';
import '../../widgets/app_loading_indicator.dart';

/// 불편신고 - 폼 형태 (1:1 문의와 구분)
/// POST /complaints 연동 (Bearer 토큰)
class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final ok = await AuthService.isLoggedIn();
    if (mounted) setState(() => _loggedIn = ok);
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) {
      showWarningSnackBar(context, '내용을 입력해주세요.', title: '확인');
      return;
    }
    if (!_loggedIn) {
      showInfoSnackBar(context, '로그인이 필요합니다.', title: '로그인');
      return;
    }
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final res = await ComplaintsApi.create(content: content);
      if (res.success && mounted) {
        _controller.clear();
        showSuccessSnackBar(context, '접수되었습니다.', title: '접수 완료');
      } else if (mounted) {
        showErrorSnackBar(context, res.error ?? '접수 실패');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, '접수 실패');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('불편신고')),
      body: SingleChildScrollView(
        padding: AppTheme.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const PhosphorIcon(
                      PhosphorIconsRegular.warning,
                      color: AppTheme.primaryDark,
                      size: 24,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '불편 사항을 신고해 주세요',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const Gap(8),
                        Text(
                          '운행 중 불편한 점, 기사님 관련 민원 등을 남겨주시면 검토 후 연락드립니다. 신고 내용은 익명으로 처리됩니다.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF4B5563),
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '불편 사항',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Gap(12),
                  TextField(
                    controller: _controller,
                    enabled: _loggedIn,
                    maxLines: 8,
                    minLines: 5,
                    decoration: InputDecoration(
                      hintText: _loggedIn
                          ? '불편했던 사항을 구체적으로 적어 주세요.\n(일시, 장소, 상황 등)'
                          : '로그인이 필요합니다.',
                    ),
                  ),
                ],
              ),
            ),
            if (!_loggedIn) ...[
              const Gap(16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentYellow.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                  border: Border.all(color: AppTheme.borderGrey),
                ),
                child: Row(
                  children: [
                    const PhosphorIcon(
                      PhosphorIconsRegular.warningCircle,
                      color: AppTheme.primaryDark,
                      size: 20,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        '로그인 후 신고하실 수 있습니다.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryDark,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Gap(24),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _loggedIn && !_loading ? _submit : null,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: AppLoadingIndicator(size: 20),
                      )
                    : PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt, color: Colors.white, size: 20),
                label: Text(_loading ? '접수 중...' : '신고하기'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
