import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/coupons_api.dart';
import '../../theme/app_theme.dart';

/// 쿠폰함 — 마일리지와 완전히 분리된 실물 상품형 쿠폰 목록
class CouponScreen extends StatefulWidget {
  const CouponScreen({super.key});

  @override
  State<CouponScreen> createState() => _CouponScreenState();
}

class _CouponScreenState extends State<CouponScreen> {
  late Future<List<UserCoupon>> _future;
  // 더미 쿠폰 신청 상태 로컬 추적 (백엔드 미반영)
  final Set<String> _pendingMockIds = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserCoupon>> _load() async {
    final coupons = await CouponsApi.getMyCoupons();
    // mock_ 쿠폰 중 신청한 것은 로컬 상태로 덮어씀
    return coupons.map((c) {
      if (c.id.startsWith('mock_') && _pendingMockIds.contains(c.id)) {
        return UserCoupon(
          id: c.id, code: c.code, name: c.name, amount: c.amount,
          validUntil: c.validUntil, receivedAt: c.receivedAt, usedAt: c.usedAt,
          status: 'pending_delivery', brand: c.brand, imageUrl: c.imageUrl,
        );
      }
      return c;
    }).toList();
  }

  void _onMockRedeemed(String id) {
    setState(() {
      _pendingMockIds.add(id);
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('쿠폰함')),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _CouponIntroSection(),
                    const Gap(20),
                    _MyCouponSection(
                      couponsFuture: _future,
                      onMockRedeemed: _onMockRedeemed,
                    ),
                    const Gap(80),
                  ],
                ),
              ),
            ),
          ),
          const _Footer(),
        ],
      ),
    );
  }
}

// ── 쿠폰 안내 섹션 ────────────────────────────────────────────────────────────

class _CouponIntroSection extends StatelessWidget {
  const _CouponIntroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade500, Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const PhosphorIcon(PhosphorIconsRegular.gift, color: Colors.white, size: 22),
              ),
              const Gap(12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('친구 추천 상품 쿠폰', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('마일리지와 별도로 지급되는 실물 쿠폰이에요', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          _RewardRow(
            label: '2명 추천',
            reward: '스타벅스 음료 쿠폰 2장',
            icon: PhosphorIconsRegular.coffee,
            color: const Color(0xFF00704A),
          ),
          const Gap(10),
          _RewardRow(
            label: '5명 추천',
            reward: '교촌치킨 세트 쿠폰',
            icon: PhosphorIconsRegular.forkKnife,
            color: const Color(0xFFC62828),
          ),
          const Gap(16),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/referrer-status'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('친구 추천하러 가기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  Gap(6),
                  PhosphorIcon(PhosphorIconsRegular.arrowRight, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.label, required this.reward, required this.icon, required this.color});
  final String label;
  final String reward;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const Gap(10),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: PhosphorIcon(icon, color: Colors.white, size: 14),
        ),
        const Gap(6),
        Expanded(
          child: Text(reward, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ── 나의 쿠폰함 ───────────────────────────────────────────────────────────────

class _MyCouponSection extends StatelessWidget {
  const _MyCouponSection({required this.couponsFuture, required this.onMockRedeemed});
  final Future<List<UserCoupon>> couponsFuture;
  final void Function(String id) onMockRedeemed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('나의 쿠폰함', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.primaryDark)),
              Gap(6),
              Text('(마일리지와 별도)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const Gap(12),
          FutureBuilder<List<UserCoupon>>(
            future: couponsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _StatusCard(
                  child: const Row(
                    children: [
                      SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                      Gap(14),
                      Text('쿠폰을 불러오는 중...', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return _StatusCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        PhosphorIcon(PhosphorIconsRegular.warning, size: 20, color: Colors.red.shade400),
                        const Gap(8),
                        const Text('쿠폰을 불러오지 못했어요.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ]),
                      const Gap(10),
                      SizedBox(
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => context.findAncestorStateOfType<_CouponScreenState>()?._refresh(),
                          child: const Text('다시 시도'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final coupons = snapshot.data ?? const <UserCoupon>[];

              if (coupons.isEmpty) {
                return _StatusCard(
                  child: Column(
                    children: [
                      PhosphorIcon(PhosphorIconsRegular.gift, size: 44, color: Colors.grey.shade300),
                      const Gap(12),
                      const Text('보유한 쿠폰이 없어요', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const Gap(4),
                      Text('친구를 추천하면 상품 쿠폰이 지급돼요!', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }

              final state = context.findAncestorStateOfType<_CouponScreenState>();
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: coupons.length,
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (_, i) => _CouponTicketCard(
                  coupon: coupons[i],
                  onRedeemed: () {
                    final c = coupons[i];
                    if (c.id.startsWith('mock_')) {
                      state?._onMockRedeemed(c.id);
                    } else {
                      state?._refresh();
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── 쿠폰 티켓 카드 ─────────────────────────────────────────────────────────────

class _CouponTicketCard extends StatefulWidget {
  const _CouponTicketCard({required this.coupon, required this.onRedeemed});
  final UserCoupon coupon;
  final VoidCallback onRedeemed;

  @override
  State<_CouponTicketCard> createState() => _CouponTicketCardState();
}

class _CouponTicketCardState extends State<_CouponTicketCard> {
  bool _loading = false;

  Future<void> _redeem() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('쿠폰 신청', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('${widget.coupon.displayTitle}\n\n쿠폰을 신청하시겠습니까?\n신청 후 관리자가 확인하여 발송해드립니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('신청하기')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await CouponsApi.redeem(widget.coupon.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('쿠폰 신청이 완료됐습니다. 관리자가 확인 후 발송해드려요.'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
        widget.onRedeemed();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color get _brandColor {
    switch (widget.coupon.brand) {
      case CouponBrand.starbucks:   return const Color(0xFF00704A);
      case CouponBrand.chicken:     return const Color(0xFFC62828);
      case CouponBrand.convenience: return const Color(0xFF1565C0);
      case CouponBrand.giftcard:    return const Color(0xFF6A1B9A);
      case CouponBrand.other:       return Colors.amber.shade700;
    }
  }

  IconData get _brandIcon {
    switch (widget.coupon.brand) {
      case CouponBrand.starbucks:   return PhosphorIconsRegular.coffee;
      case CouponBrand.chicken:     return PhosphorIconsRegular.forkKnife;
      case CouponBrand.convenience: return PhosphorIconsRegular.storefront;
      case CouponBrand.giftcard:    return PhosphorIconsRegular.gift;
      case CouponBrand.other:       return PhosphorIconsRegular.ticket;
    }
  }

  String get _brandLabel {
    switch (widget.coupon.brand) {
      case CouponBrand.starbucks:   return 'STARBUCKS';
      case CouponBrand.chicken:     return 'CHICKEN';
      case CouponBrand.convenience: return 'STORE';
      case CouponBrand.giftcard:    return 'GIFT';
      case CouponBrand.other:       return 'COUPON';
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupon = widget.coupon;
    final used = coupon.isUsed || coupon.isDelivered;
    final pending = coupon.isPendingDelivery;
    final color = _brandColor;
    final validText = _formatDate(coupon.validUntil);

    return Opacity(
      opacity: used ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // 브랜드 영역
                      Container(
                        width: 100,
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withValues(alpha: 0.75)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: PhosphorIcon(_brandIcon, color: Colors.white, size: 22),
                            ),
                            const Gap(8),
                            Text(
                              _brandLabel,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // 점선 구분선
                      SizedBox(width: 18, child: CustomPaint(painter: _DashLinePainter(color: Colors.grey.shade200))),

                      // 쿠폰 정보
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                coupon.displayTitle,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('실물 상품 쿠폰', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
                              ),
                              const Gap(8),
                              if (validText != null)
                                Row(
                                  children: [
                                    PhosphorIcon(PhosphorIconsRegular.calendarBlank, size: 12, color: Colors.grey.shade400),
                                    const Gap(4),
                                    Text('~ $validText', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ],
                                ),
                              const Gap(8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _CouponStatusBadge(coupon: coupon, color: color),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 신청하기 버튼 (active 상태일 때만)
                if (!used && !pending)
                  GestureDetector(
                    onTap: _loading ? null : _redeem,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: color,
                        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
                      ),
                      child: Center(
                        child: _loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                '신청하기',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                              ),
                      ),
                    ),
                  ),

                // 발송 대기 중 안내
                if (pending)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    color: Colors.orange.shade50,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded, size: 15, color: Colors.orange.shade700),
                        const Gap(6),
                        Text('신청완료 — 관리자 발송 대기 중', style: TextStyle(fontSize: 13, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),

            // 사용완료 스탬프
            if (used)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(coupon.isDelivered ? '발송완료' : '사용완료', style: TextStyle(color: Colors.grey.shade500, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CouponStatusBadge extends StatelessWidget {
  const _CouponStatusBadge({required this.coupon, required this.color});
  final UserCoupon coupon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg, border, text;

    if (coupon.isDelivered) {
      label = '발송완료'; bg = Colors.grey.shade100; border = Colors.grey.shade300; text = Colors.grey.shade500;
    } else if (coupon.isPendingDelivery) {
      label = '발송대기'; bg = Colors.orange.shade50; border = Colors.orange.shade200; text = Colors.orange.shade700;
    } else if (coupon.isUsed) {
      label = '사용완료'; bg = Colors.grey.shade100; border = Colors.grey.shade300; text = Colors.grey.shade500;
    } else {
      label = '사용가능'; bg = color.withValues(alpha: 0.1); border = color.withValues(alpha: 0.3); text = color;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text)),
    );
  }
}

// ── 상태 카드 ─────────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: child,
    );
  }
}

// ── 점선 ─────────────────────────────────────────────────────────────────────

class _DashLinePainter extends CustomPainter {
  const _DashLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const dashH = 5.0;
    const gapH = 4.0;
    double y = 0;
    final paint = Paint()..color = color..strokeWidth = 1.5..strokeCap = StrokeCap.round;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y), Offset(size.width / 2, y + dashH), paint);
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(_DashLinePainter old) => old.color != color;
}

// ── 푸터 ─────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

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
          '쿠폰은 마일리지와 별도로 지급되며, 유효기간은 발급일로부터 30일입니다.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── 유틸 ─────────────────────────────────────────────────────────────────────

String? _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(iso);
  return m != null ? '${m[1]}.${m[2]}.${m[3]}' : iso;
}
