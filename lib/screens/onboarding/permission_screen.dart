import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/onboarding_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header.dart';

/// 1번 이미지: 접근권한 알림
class PermissionScreen extends StatelessWidget {
  const PermissionScreen({super.key});

  Future<void> _requestPermission(Permission permission) async {
    await permission.request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(height: 160),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '접근권한 알림',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '권한 허용후 서비스를 이용할 수 있습니다.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                    const SizedBox(height: 24),
                    _PermissionItem(
                      label: '위치',
                      onTap: () => _requestPermission(Permission.location),
                    ),
                    const SizedBox(height: 12),
                    _PermissionItem(
                      label: '전화',
                      onTap: () => _requestPermission(Permission.phone),
                    ),
                    const SizedBox(height: 12),
                    _PermissionItem(
                      label: '저장공간',
                      onTap: () => _requestPermission(Permission.storage),
                    ),
                    const SizedBox(height: 12),
                    _PermissionItem(
                      label: '마이크',
                      onTap: () => _requestPermission(Permission.microphone),
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
                  onPressed: () async {
                    await OnboardingService.setPermissionDone();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/terms');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentYellow,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('확인'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  const _PermissionItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            const Spacer(),
            Icon(Icons.keyboard_arrow_down, color: AppTheme.lightBlue),
          ],
        ),
      ),
    );
  }
}
