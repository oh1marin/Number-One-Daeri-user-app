import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_theme.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('이용내역')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(count: 0),
          const _ReceiptBanner(),
          const Expanded(child: _EmptyState()),
        ],
      ),
    );
  }
}

// ── 안내 카드 ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE3F2FD), const Color(0xFFE8EAF6).withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blue.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade400.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(PhosphorIconsRegular.car, color: Colors.red.shade400, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('운행내역 안내', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 6),
                const Text('고객님이 이용하신 운행내역입니다.', style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    PhosphorIcon(PhosphorIconsRegular.listBullets, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text('$count건', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1, end: 0, curve: Curves.easeOut);
  }
}

// ── 현금영수증 발행 배너 ───────────────────────────────────────────────────────

class _ReceiptBanner extends StatelessWidget {
  const _ReceiptBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/cash-receipt'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderGrey),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const PhosphorIcon(PhosphorIconsRegular.receipt, color: AppTheme.primaryDark, size: 20),
            ),
            const Gap(12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('현금영수증 발행', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryDark)),
                  Text('휴대폰번호 또는 사업자번호로 발행', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('발행하기', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

// ── 빈 상태 ───────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2),
              ],
            ),
            child: PhosphorIcon(PhosphorIconsRegular.car, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text('운행 내역이 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOut);
  }
}
