import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/legal_urls.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';

const _kHotline = '010-2184-8822';
const _kHotlineDial = '01021848822';

/// 앱 정보 · 고객센터 · 약관 링크
class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  Future<void> _callHotline() async {
    final uri = Uri.parse('tel:$_kHotlineDial');
    if (!await launchUrl(uri)) {
      if (mounted) showErrorSnackBar(context, '전화 연결을 할 수 없습니다.');
    }
  }

  Future<void> _copyHotline() async {
    await Clipboard.setData(const ClipboardData(text: _kHotline));
    if (mounted) showSuccessSnackBar(context, '번호가 복사되었습니다.', title: '복사');
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showErrorSnackBar(context, '페이지를 열 수 없습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = _info?.version ?? '—';
    final build = _info?.buildNumber ?? '—';

    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        title: const Text('앱 정보'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderGrey),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const Gap(12),
                const Text(
                  '일등대리',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const Gap(8),
                Text(
                  '버전 $version (빌드 $build)',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Gap(20),
          const Text(
            '고객센터',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.primaryDark,
            ),
          ),
          const Gap(8),
          _ActionTile(
            icon: PhosphorIconsRegular.phone,
            title: _kHotline,
            subtitle: '전화 문의 (24시간 접수)',
            onTap: _callHotline,
            trailing: TextButton(
              onPressed: _copyHotline,
              child: const Text('복사'),
            ),
          ),
          const Gap(24),
          const Text(
            '약관 및 정책',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppTheme.primaryDark,
            ),
          ),
          const Gap(8),
          _ActionTile(
            icon: PhosphorIconsRegular.fileText,
            title: '서비스 이용약관',
            onTap: () => _openUrl(LegalUrls.serviceTerms),
          ),
          _ActionTile(
            icon: PhosphorIconsRegular.shield,
            title: '개인정보 취급방침',
            onTap: () => _openUrl(LegalUrls.privacy),
          ),
          _ActionTile(
            icon: PhosphorIconsRegular.mapPin,
            title: '위치기반 서비스 이용약관',
            onTap: () => _openUrl(LegalUrls.location),
          ),
          const Gap(24),
          Text(
            'ⓒ 2026 일등대리',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: ListTile(
        leading: PhosphorIcon(icon, color: AppTheme.primaryDark, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
            : null,
        trailing: trailing ??
            PhosphorIcon(
              PhosphorIconsRegular.caretRight,
              size: 16,
              color: Colors.grey.shade400,
            ),
        onTap: onTap,
      ),
    );
  }
}
