import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

/// 사고/과태료 - 교통사고·과태료 안내
class AccidentPenaltyScreen extends StatelessWidget {
  const AccidentPenaltyScreen({super.key});

  static const _faxNumber = '031-247-1988';
  static const _supportPhone = '01021848822';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사고/과태료')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: PhosphorIconsRegular.phone,
                          label: '고객센터 전화',
                          color: Colors.orange,
                          onTap: () => launchUrl(Uri(scheme: 'tel', path: _supportPhone)),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: _ActionButton(
                          icon: PhosphorIconsRegular.chatCircle,
                          label: '1:1 문의',
                          color: Colors.red,
                          onTap: () => Navigator.pushNamed(context, '/qa'),
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),
                  _AccidentCard(),
                  const Gap(16),
                  _PenaltyCard(faxNumber: _faxNumber),
                ],
              ),
            ),
          ),
          _Footer(),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(icon, color: Colors.white, size: 20),
              const Gap(8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccidentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PhosphorIcon(
                  PhosphorIconsRegular.warning,
                  color: Colors.red.shade700,
                  size: 24,
                ),
              ),
              const Gap(12),
              const Text(
                '운행 중 교통사고 발생 시',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            '일등대리는 항상 고객의 안전을 최우선으로 여기며, 운행 중 예상치 못한 교통사고 발생 시 신속한 처리를 위해 최선을 다하겠습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
          const Gap(12),
          Text(
            '사고 처리 과정 중 불편사항이 발생한 경우, 고객센터로 문의해 주시면 보다 신속하게 처리해 드립니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PenaltyCard extends StatelessWidget {
  const _PenaltyCard({required this.faxNumber});
  final String faxNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: PhosphorIcon(
                  PhosphorIconsRegular.camera,
                  color: Colors.amber.shade700,
                  size: 24,
                ),
              ),
              const Gap(12),
              const Text(
                '과태료 부과 시',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            '일등대리는 운행 중 발생한 과태료에 대하여 100% 처리를 원칙으로 하고 있습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
          const Gap(12),
          Text(
            '발부받으신 과태료 부과서 사본에 수신하신 고객님의 전화번호, 입금받으실 계좌번호를 기재하여 보내주시면 신속하게 처리하여 드립니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
          const Gap(12),
          Text(
            '처리 기한은 팩스 수신 후 최대 7일 정도 소요될 수 있습니다.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5),
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentYellow.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsRegular.fileDoc,
                  color: Colors.amber.shade800,
                  size: 20,
                ),
                const Gap(10),
                Text(
                  '팩스번호 : $faxNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
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
