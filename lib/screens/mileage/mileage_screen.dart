import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/mileage_api.dart';
import '../../utils/mileage_balance_cache.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/signup_bonus_mileage_notice.dart';

/// 마일리지 화면 — 순수 마일리지만 표시 (쿠폰 완전 분리)
class MileageScreen extends StatefulWidget {
  const MileageScreen({super.key});

  @override
  State<MileageScreen> createState() => _MileageScreenState();
}

class _MileageScreenState extends State<MileageScreen> with WidgetsBindingObserver {
  int _balance = 0;
  int _withdrawable = 0;
  List<MileageHistoryItem> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from background (or after receiving a push),
    // refresh to reflect server-side mileage changes.
    if (state == AppLifecycleState.resumed && mounted) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      MileageBalanceCache.invalidate();
      final results = await Future.wait([
        MileageBalanceCache.getBalance(force: true),
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = loadErrorMessage(e, fallback: '마일리지를 불러오지 못했습니다.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityReconnectListener(
      onReconnect: _load,
      child: Scaffold(
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
              ? LoadErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _BalanceCard(
                              balance: _balance,
                              withdrawable: _withdrawable,
                              fmt: formatKrw,
                              onGifticonTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/gifticon-shop',
                                  arguments: _balance,
                                );
                                _load();
                              },
                            ),
                            const Gap(12),
                            const SignupBonusMileageNotice(),
                            const Gap(12),
                            _GifticonExchangeBanner(
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  '/gifticon-shop',
                                  arguments: _balance,
                                );
                                _load();
                              },
                            ),
                            const Gap(12),
                            _CouponSeparateBanner(),
                            const Gap(24),
                            Row(
                              children: [
                                const Text(
                                  '이용 내역',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppTheme.primaryDark,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '쿠폰 제외',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(12),
                          ]),
                        ),
                      ),
                      if (_history.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverToBoxAdapter(child: _EmptyHistory()),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final e = _history[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _history.length - 1 ? 8 : 0,
                                  ),
                                  child: _TransactionItem(
                                    date: formatDateShort(e.createdAt),
                                    desc: e.description ?? _typeLabel(e.type),
                                    amount: e.amount,
                                    balance: e.balance,
                                    type: e.type,
                                    fmt: formatKrw,
                                  ),
                                );
                              },
                              childCount: _history.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: Gap(40)),
                    ],
                  ),
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
  const _BalanceCard({
    required this.balance,
    required this.withdrawable,
    required this.fmt,
    this.onGifticonTap,
  });
  final int balance;
  final int withdrawable;
  final String Function(int) fmt;
  final VoidCallback? onGifticonTap;

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
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onGifticonTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 18),
                        Gap(8),
                        Text(
                          '기프티콘 교환',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(10),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/withdrawal'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentYellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '출금신청',
                    style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
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
            ],
          ),
        ],
      ),
    );
  }
}

// ── 기프티콘 교환 배너 ─────────────────────────────────────────────────────────

class _GifticonExchangeBanner extends StatelessWidget {
  const _GifticonExchangeBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.teal.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 22),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '마일리지 기프티콘 교환몰',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    '메가MGC커피 · BBQ 치킨 모바일 교환권',
                    style: TextStyle(fontSize: 11, color: Colors.green.shade800, height: 1.35),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.green.shade700),
          ],
        ),
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
                '이벤트·추천 등으로 받은 쿠폰은 쿠폰함에서 확인할 수 있어요.',
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
