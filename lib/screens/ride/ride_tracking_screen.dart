import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/rides_api.dart';
import '../../models/ride.dart';
import '../../theme/app_theme.dart';
import '../../utils/ride_status_ui.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/load_error_view.dart';

/// 호출 후 배차·운행 상태 타임라인
class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({
    super.key,
    required this.rideId,
    this.pickupLabel,
    this.dropoffLabel,
  });

  final String rideId;
  final String? pickupLabel;
  final String? dropoffLabel;

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  Ride? _ride;
  String? _error;
  bool _loading = true;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final ride = await RidesApi.get(widget.rideId);
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _loading = false;
        _error = null;
      });
      final status = ride?.status ?? '';
      if (RideStatusUi.isTerminal(status)) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = loadErrorMessage(e, fallback: '배차 상태를 불러오지 못했습니다.');
      });
    }
  }

  Future<void> _callCenter() async {
    final uri = Uri.parse('tel:01021848822');
    await launchUrl(uri);
  }

  String get _status => _ride?.status ?? 'requested';

  @override
  Widget build(BuildContext context) {
    final pickup = (_ride?.pickup.isNotEmpty == true)
        ? _ride!.pickup
        : (widget.pickupLabel ?? '');
    final dropoff = (_ride?.dropoff.isNotEmpty == true)
        ? _ride!.dropoff
        : (widget.dropoffLabel ?? '');

    return ConnectivityReconnectListener(
      onReconnect: () => _load(),
      child: Scaffold(
        backgroundColor: AppTheme.surfaceGrey,
        appBar: AppBar(
          title: const Text('배차 현황'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : () => _load(),
            ),
          ],
        ),
        body: _loading && _ride == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _ride == null
                ? LoadErrorView(message: _error!, onRetry: () => _load())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusHeader(
                          status: _status,
                          driverName: _ride?.driverName ?? '',
                          rideId: widget.rideId,
                        ),
                        const Gap(16),
                        _TimelineCard(activeIndex: RideStatusUi.timelineIndex(_status)),
                        if (pickup.isNotEmpty || dropoff.isNotEmpty) ...[
                          const Gap(16),
                          _RouteCard(pickup: pickup, dropoff: dropoff),
                        ],
                        const Gap(24),
                        OutlinedButton.icon(
                          onPressed: _callCenter,
                          icon: const PhosphorIcon(PhosphorIconsRegular.phone),
                          label: const Text('고객센터 010-2184-8822'),
                        ),
                        if (RideStatusUi.isTerminal(_status)) ...[
                          const Gap(12),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('확인'),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.status,
    required this.driverName,
    required this.rideId,
  });

  final String status;
  final String driverName;
  final String rideId;

  @override
  Widget build(BuildContext context) {
    final cancelled = RideStatusUi.normalize(status) == 'cancelled' ||
        RideStatusUi.normalize(status) == 'canceled';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: cancelled
              ? [Colors.grey.shade600, Colors.grey.shade700]
              : [const Color(0xFF1A2F7A), AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            RideStatusUi.title(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Gap(8),
          Text(
            RideStatusUi.subtitle(status, driverName: driverName),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), height: 1.4),
          ),
          if (rideId.isNotEmpty) ...[
            const Gap(12),
            Text(
              '접수번호 $rideId',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '진행 단계',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primaryDark),
          ),
          const Gap(16),
          ...List.generate(RideStatusUi.timelineSteps.length, (i) {
            final step = RideStatusUi.timelineSteps[i];
            final done = activeIndex < 0 ? false : i <= activeIndex;
            final current = i == activeIndex;
            return Padding(
              padding: EdgeInsets.only(bottom: i < RideStatusUi.timelineSteps.length - 1 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: done
                          ? (current ? AppTheme.accentBlue : AppTheme.primaryDark)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      done ? Icons.check : Icons.circle_outlined,
                      size: 16,
                      color: done ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    step.$2,
                    style: TextStyle(
                      fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                      color: done ? AppTheme.primaryDark : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.pickup, required this.dropoff});

  final String pickup;
  final String dropoff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pickup.isNotEmpty) ...[
            const Text('출발', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const Gap(4),
            Text(pickup, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
          if (pickup.isNotEmpty && dropoff.isNotEmpty) const Gap(12),
          if (dropoff.isNotEmpty) ...[
            const Text('도착', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            const Gap(4),
            Text(dropoff, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
