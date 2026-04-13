import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/auth_api.dart';
import '../../routes/app_router.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading             = false;
  bool _obscurePassword     = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;
    setState(() { _error = null; _loading = true; });
    try {
      final res = await AuthApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (res.success && res.data != null) {
        await AuthService.saveTokens(
          accessToken: res.data!.accessToken,
          refreshToken: res.data!.refreshToken,
        );
        if (mounted) Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
      } else {
        setState(() { _error = res.error ?? '로그인에 실패했습니다.'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = '로그인 중 오류가 발생했습니다.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 로고 + 타이틀
                _buildHeader(),
                const Gap(32),

                // 폼 카드
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.primaryDark,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDark.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/icons/logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Center(
                child: PhosphorIcon(PhosphorIconsRegular.car, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const Gap(16),
        const Text(
          '일등대리',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryDark,
            letterSpacing: -0.5,
          ),
        ),
        const Gap(4),
        const Text(
          '관리자 로그인',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 에러 메시지
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFE53935), size: 16),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Color(0xFFE53935), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ],

            // 이메일
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.isEmpty ? '이메일을 입력하세요' : null,
            ),
            const Gap(14),

            // 비밀번호
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '비밀번호',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (_formKey.currentState!.validate()) _login();
              },
              validator: (v) => v == null || v.isEmpty ? '비밀번호를 입력하세요' : null,
            ),
            const Gap(24),

            // 로그인 버튼
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () { if (_formKey.currentState!.validate()) _login(); },
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('로그인'),
            ),

            const Gap(14),

            // 회원가입
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.register),
              child: const Text('회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
