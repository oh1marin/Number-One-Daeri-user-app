import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/rides_api.dart';
import '../../models/ride.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_friendly_text.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with WidgetsBindingObserver {
  List<Ride> _items = [];
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
    if (state == AppLifecycleState.resumed && mounted) {
      _load(silent: true);
    }
  }

  void _recallRide(Ride ride) {
    Navigator.pushNamed(
      context,
      '/call-map',
      arguments: {
        'pickup': ride.pickup,
        'dropoff': ride.dropoff,
      },
    );
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await RidesApi.list();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = toFriendlyError(e, fallback: '이용내역을 불러오지 못했습니다.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('이용내역')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      _InfoCard(count: _items.length),
                      const _ReceiptBanner(),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: _EmptyState(),
                        )
                      else
                        ..._items.map((r) => _RideItem(ride: r, onRecall: _recallRide)),
                      const SizedBox(height: 24),
                    ],
                  ),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsRegular.warning,
              size: 40,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideItem extends StatelessWidget {
  const _RideItem({required this.ride, required this.onRecall});

  final Ride ride;
  final void Function(Ride ride) onRecall;

  @override
  Widget build(BuildContext context) {
    final date = formatDateShort(ride.date);
    final time = ride.time.trim();
    final when = time.isEmpty ? date : '$date $time';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(when, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${formatKrw(ride.total)}원',
                style: const TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _RecallLine(
            label: '출발',
            address: ride.pickup,
            onTap: ride.pickup.trim().isEmpty ? null : () => onRecall(ride),
          ),
          const SizedBox(height: 3),
          _RecallLine(
            label: '도착',
            address: ride.dropoff,
            onTap: ride.dropoff.trim().isEmpty ? null : () => onRecall(ride),
          ),
          if (ride.pickup.trim().isNotEmpty && ride.dropoff.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onRecall(ride),
                icon: const Icon(Icons.replay_rounded, size: 16),
                label: const Text('이 경로로 다시 호출'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.accentBlue,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecallLine extends StatelessWidget {
  const _RecallLine({
    required this.label,
    required this.address,
    this.onTap,
  });

  final String label;
  final String address;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '$label: $address',
      style: TextStyle(
        fontSize: 12,
        color: onTap != null ? AppTheme.accentBlue : Colors.black87,
        decoration: onTap != null ? TextDecoration.underline : null,
      ),
    );
    if (onTap == null) return text;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: text),
            const Icon(Icons.chevron_right, size: 16, color: AppTheme.accentBlue),
          ],
        ),
      ),
    );
  }
}
