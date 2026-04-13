import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/mileage_api.dart';
import '../../theme/app_theme.dart';

/// 마일리지 화면 — 순수 마일리지만 표시 (쿠폰 완전 분리)
class MileageScreen extends StatefulWidget {
  const MileageScreen({super.key});

  @override
  State<MileageScreen> createState() => _MileageScreenState();
}

class _MileageScreenState extends State<MileageScreen> {
  int _balance = 0;
  int _withdrawable = 0;
  List<MileageHistoryItem> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        MileageApi.getBalance(),
        MileageApi.getHistory(),
      ]);
      if (mounted) {
        final bal = results[0] as MileageBalance;
        final hist = results[1] as MileageHistoryResponse;
        setState(() {
          _balance = bal.balance;
          _withdrawable = bal.withdrawable;
          // 쿠폰 관련 항목은 완전히 제외 — 쿠폰은 쿠폰함에서 별도 관리
          _history = hist.items.where((e) => !e.isCouponRelated).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = '잔액을 불러올 수 없습니다.'; });
    }
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마일리지'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // 마일리지 잔액 카드
                      _BalanceCard(balance: _balance, withdrawable: _withdrawable, fmt: _fmt),
                      const Gap(12),

                      // 쿠폰 분리 안내 배너
                      _CouponSeparateBanner(),
                      const Gap(24),

                      // 이용내역 헤더
                      Row(
                        children: [
                          const Text('이용 내역', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.primaryDark)),
                          const Spacer(),
                          Text('쿠폰 제외', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        ],
                      ),
                      const Gap(12),

                      if (_history.isEmpty)
                        _EmptyHistory()
                      else
                        ..._history.map((e) => _TransactionItem(
                          date: e.createdAt ?? '-',
                          desc: e.description ?? _typeLabel(e.type),
                          amount: e.amount,
                          balance: e.balance,
                          type: e.type,
                          fmt: _fmt,
                        )),
                      const Gap(40),
                    ],
                  ),
                ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'earn':     return '적립';
      case 'use':      return '사용';
      case 'withdraw': return '출금';
      default:         return type;
    }
  }
}

// ── 잔액 카드 ─────────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.withdrawable, required this.fmt});
  final int balance;
  final int withdrawable;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2F7A), AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '순수 마일리지',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              PhosphorIcon(PhosphorIconsRegular.wallet, color: Colors.white.withValues(alpha: 0.5), size: 28),
            ],
          ),
          const Gap(16),
          Text(
            '${fmt(balance)}원',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const Gap(4),
          Text('가입 시 10,000원 / 카드 결제 10% 적립', style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
          const Gap(16),
          Divider(color: Colors.white.withValues(alpha: 0.15)),
          const Gap(12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('출금가능', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  const Gap(2),
                  Text('${fmt(withdrawable)}원', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/withdrawal'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '출금신청',
                    style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 쿠폰 분리 안내 ─────────────────────────────────────────────────────────────

class _CouponSeparateBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/coupon'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            PhosphorIcon(PhosphorIconsRegular.ticket, color: Colors.amber.shade700, size: 18),
            const Gap(10),
            Expanded(
              child: Text(
                '쿠폰(스타벅스, 치킨 등)은 마일리지와 별도로 쿠폰함에서 확인할 수 있어요.',
                style: TextStyle(fontSize: 12, color: Colors.amber.shade800, height: 1.4),
              ),
            ),
            const Gap(6),
            PhosphorIcon(PhosphorIconsRegular.caretRight, color: Colors.amber.shade600, size: 14),
          ],
        ),
      ),
    );
  }
}

// ── 빈 내역 ───────────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          PhosphorIcon(PhosphorIconsRegular.listBullets, size: 40, color: Colors.grey.shade300),
          const Gap(12),
          Text('이용 내역이 없습니다.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── 에러 뷰 ───────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(PhosphorIconsRegular.warning, size: 48, color: Colors.grey.shade400),
            const Gap(16),
            Text(error, style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
            const Gap(16),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

// ── 거래 항목 ─────────────────────────────────────────────────────────────────

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.date, required this.desc, required this.amount,
    required this.balance, required this.type, required this.fmt,
  });

  final String date;
  final String desc;
  final int amount;
  final int balance;
  final String type;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final isPlus = type == 'earn';
    final isWithdraw = type == 'withdraw';
    final amountColor = isPlus
        ? const Color(0xFF1A2F7A)
        : isWithdraw
            ? AppTheme.primaryDark
            : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: amountColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: PhosphorIcon(
              isPlus ? PhosphorIconsRegular.arrowDown : PhosphorIconsRegular.arrowUp,
              color: amountColor, size: 18,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryDark)),
                const Gap(2),
                Text(date, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPlus ? '+' : '-'}${fmt(amount.abs())}원',
                style: TextStyle(color: amountColor, fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text('잔액 ${fmt(balance)}원', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
