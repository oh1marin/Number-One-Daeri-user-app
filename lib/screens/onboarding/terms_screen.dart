import 'package:flutter/material.dart';

import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

/// 2,3번 이미지: 약관 동의
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _service = false;
  bool _privacy = false;
  bool _location = false;
  bool _age14 = false;
  bool _allAgree = false;

  void _updateAll() {
    setState(() {
      _allAgree = _service && _privacy && _location && _age14;
    });
  }

  void _setAll(bool v) {
    setState(() {
      _service = v;
      _privacy = v;
      _location = v;
      _age14 = v;
      _allAgree = v;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(height: 160),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TermRow(
                      icon: Icons.description,
                      label: '약관',
                      checked: _allAgree,
                      onTap: () => _setAll(!_allAgree),
                    ),
                    const SizedBox(height: 16),
                    _TermRow(
                      icon: Icons.person_outline,
                      label: '서비스 이용약관',
                      checked: _service,
                      onTap: () {
                        setState(() => _service = !_service);
                        _updateAll();
                      },
                    ),
                    _TermRow(
                      icon: Icons.visibility_outlined,
                      label: '개인정보 취급방침',
                      checked: _privacy,
                      onTap: () {
                        setState(() => _privacy = !_privacy);
                        _updateAll();
                      },
                    ),
                    _TermRow(
                      icon: Icons.location_on_outlined,
                      label: '위치기반 서비스 이용약관',
                      checked: _location,
                      onTap: () {
                        setState(() => _location = !_location);
                        _updateAll();
                      },
                    ),
                    _TermRow(
                      icon: Icons.arrow_upward,
                      label: '본인은 만 14세 이상입니다.',
                      checked: _age14,
                      onTap: () {
                        setState(() => _age14 = !_age14);
                        _updateAll();
                      },
                    ),
                    _TermRow(
                      icon: Icons.sync,
                      label: '전체동의',
                      checked: _allAgree,
                      onTap: () => _setAll(!_allAgree),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '몇명만 추천해도, 십만원이상의 혜택을 가져갈 수 있어요!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _service && _privacy && _location && _age14
                      ? () async {
                          await OnboardingService.setTermsDone();
                          if (context.mounted) {
                            Navigator.of(context)
                                .pushReplacementNamed('/phone-verify');
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('동의하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  const _TermRow({
    required this.icon,
    required this.label,
    required this.checked,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              color: checked ? AppTheme.accentBlue : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
