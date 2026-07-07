import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../api/account_api.dart';
import '../../api/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';

/// 계정삭제
class AccountDeleteScreen extends StatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  State<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends State<AccountDeleteScreen> {
  bool _keepAccount = true;
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정삭제')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 안내 카드
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8, offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.info_outline_rounded,
                                  color: Color(0xFFE53935), size: 20),
                            ),
                            const Gap(12),
                            const Text(
                              '계정 삭제 안내',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const Gap(16),
                        Text(
                          '저의 일등대리는 고객님에게 공지안내(푸시사용), 마일리지 안내, 내역제공 및 출금요청 등의 제공을 위해 고객님의 핸드폰번호를 수집하고 있습니다.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                        ),
                        const Gap(12),
                        Text(
                          '아래의 계정삭제 버튼을 눌러서 고객님의 계정정보를 삭제할 수 있습니다. 삭제 후 기록은 복구할 수 없습니다.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                        ),
                        const Gap(20),
                        Divider(color: AppTheme.borderGrey),
                        const Gap(12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '계정정보를 유지하겠습니다.',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.primaryDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Switch.adaptive(
                              value: _keepAccount,
                              onChanged: (v) => setState(() => _keepAccount = v),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(24),

                  // 삭제 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: (_keepAccount || _deleting) ? null : _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side: BorderSide(
                          color: _keepAccount ? AppTheme.borderGrey : const Color(0xFFE53935),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('계정삭제', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _SettingsFooter(),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('계정 삭제', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('계정을 삭제하시겠습니까?\n삭제된 정보는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || _deleting) return;

    setState(() => _deleting = true);
    ApiClient.suppressAuthRecovery = true;
    var cleared = false;
    SessionService.markAuthInvalid();
    try {
      try {
        await AccountApi.deleteMe().timeout(const Duration(seconds: 15));
      } on DioException catch (e) {
        if (!SessionService.shouldTreatDeleteAsSuccess(e)) rethrow;
      } on TimeoutException {
        // 서버 응답이 없어도 탈퇴 요청은 나갔을 수 있음 → 로컬 세션 정리
      }

      if (mounted) {
        showSuccessSnackBar(context, '계정이 삭제되었습니다.', title: '완료');
      }
      await SessionService.wipeAllLocalData();
      cleared = true;
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(context, '계정 삭제에 실패했습니다. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _deleting = false);
      if (!cleared && mounted) {
        // 화면에 로딩만 남는 경우 방지
        final loggedIn = await AuthService.isLoggedIn();
        if (!loggedIn) {
          SessionService.markAuthInvalid();
          SessionService.scheduleOnboardingRedirect();
        }
        ApiClient.suppressAuthRecovery = false;
      } else if (cleared) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          ApiClient.suppressAuthRecovery = false;
        });
      }
    }
  }
}

class _SettingsFooter extends StatelessWidget {
  const _SettingsFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 14,
        bottom: MediaQuery.of(context).padding.bottom + 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceGrey,
        border: Border(top: BorderSide(color: AppTheme.borderGrey)),
      ),
      child: const Center(
        child: Text(
          'ⓒ 2026 일등대리. All rights reserved.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
        ),
      ),
    );
  }
}
