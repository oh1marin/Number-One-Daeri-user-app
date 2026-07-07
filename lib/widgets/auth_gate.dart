import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// 로그인 없이 /home 등에 들어오는 경우 전화번호 인증으로 보냄.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _loggedIn;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    bool loggedIn = false;
    try {
      loggedIn = await AuthService.isLoggedIn().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
    } catch (_) {
      loggedIn = false;
    }
    if (!mounted) return;
    if (!loggedIn) {
      Navigator.of(context).pushReplacementNamed('/logged-out');
      return;
    }
    setState(() => _loggedIn = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn != true) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentBlue),
        ),
      );
    }
    return widget.child;
  }
}
