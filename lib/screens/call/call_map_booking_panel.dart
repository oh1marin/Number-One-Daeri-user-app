part of 'call_map_screen.dart';

const int _kMaxWaypoints = 3;

/// 하단 주소·요금·결제 UI. 칩 탭 시 **이 State만** [setState] 한다.
class _CallBookingPanel extends StatefulWidget {
  const _CallBookingPanel({
    super.key,
    required this.departureAddr,
    required this.waypoints,
    required this.destination,
    this.destinationLabel,
    required this.distanceKm,
    required this.estimate,
    required this.isEstimateLoading,
    required this.onDepartureTap,
    required this.onDestinationTap,
    required this.onAddWaypoint,
    required this.onRemoveWaypoint,
    required this.onRefreshGps,
    required this.onOpenCallFlow,
  });

  final String departureAddr;
  final List<RideWaypoint> waypoints;
  final PlaceSearchResult? destination;
  final String? destinationLabel;
  final double distanceKm;
  final EstimateResult? estimate;
  final bool isEstimateLoading;
  final VoidCallback onDepartureTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onAddWaypoint;
  final void Function(int index) onRemoveWaypoint;
  final VoidCallback onRefreshGps;
  final void Function(BuildContext context) onOpenCallFlow;

  @override
  State<_CallBookingPanel> createState() => _CallBookingPanelState();
}

class _CallBookingPanelState extends State<_CallBookingPanel> {
  FareType selectedFare = FareType.normal;
  PaymentMethod selectedPayment = PaymentMethod.cash;

  EstimateResult? _estimate;
  bool _isEstimateLoading = false;

  @override
  void initState() {
    super.initState();
    _estimate = widget.estimate;
    _isEstimateLoading = widget.isEstimateLoading;
  }

  @override
  void didUpdateWidget(covariant _CallBookingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destination != widget.destination ||
        oldWidget.destinationLabel != widget.destinationLabel ||
        oldWidget.departureAddr != widget.departureAddr ||
        oldWidget.distanceKm != widget.distanceKm ||
        oldWidget.waypoints.length != widget.waypoints.length) {
      _estimate = widget.estimate;
      _isEstimateLoading = widget.isEstimateLoading;
    }
  }

  /// 견적만 갱신 — 부모 [setState] 없이 패널만 다시 그림.
  void syncEstimate({
    required EstimateResult? estimate,
    required bool isEstimateLoading,
  }) {
    if (!mounted) return;
    setState(() {
      _estimate = estimate;
      _isEstimateLoading = isEstimateLoading;
    });
  }

  int get _fareNormal => _estimate?.normal ?? 0;
  int get _fareFast => _estimate?.fast ?? 0;
  int get _farePremium => _estimate?.premium ?? 0;

  int get _selectedFareAmount {
    switch (selectedFare) {
      case FareType.premium:
        return _farePremium;
      case FareType.fast:
        return _fareFast;
      case FareType.normal:
        return _fareNormal;
    }
  }

  String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final destText = widget.destinationLabel ??
        destination?.name ??
        '도착 : 어디로 가세요?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AddressRow(
                label: '출발',
                text: widget.departureAddr,
                onTap: widget.onDepartureTap,
                onRefresh: widget.onRefreshGps,
              ),
              for (var i = 0; i < widget.waypoints.length; i++) ...[
                const Gap(6),
                _AddressRow(
                  label: '경유',
                  text: widget.waypoints[i].name,
                  compact: true,
                  onDelete: () => widget.onRemoveWaypoint(i),
                ),
              ],
              const Gap(6),
              Text(
                '어디로 모실까요?',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
              ),
              const Gap(6),
              InkWell(
                onTap: widget.onDestinationTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: destination != null
                          ? AppTheme.accentBlue.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          destination != null ? '도착 : $destText' : destText,
                          key: ValueKey(
                            destination != null
                                ? '${destination.lat}_${destination.lng}_$destText'
                                : 'dest-empty',
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: destination != null
                                ? Colors.black87
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (widget.waypoints.length < _kMaxWaypoints)
                        TextButton(
                          onPressed: widget.onAddWaypoint,
                          child: const Text('경유', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
              if (destination != null) ...[
                const Gap(8),
                Text(
                  widget.waypoints.isEmpty
                      ? '${widget.distanceKm.toStringAsFixed(1)} km'
                      : '${widget.distanceKm.toStringAsFixed(1)} km · 경유 ${widget.waypoints.length}곳',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Gap(6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FareChip(
                        icon: PhosphorIconsFill.car,
                        label: '프리미엄',
                        fare: _farePremium,
                        isLoading: _isEstimateLoading,
                        color: Colors.red,
                        selected: selectedFare == FareType.premium,
                        onTap: () =>
                            setState(() => selectedFare = FareType.premium),
                      ),
                      const Gap(8),
                      _FareChip(
                        icon: PhosphorIconsFill.car,
                        label: '빠른 호출',
                        fare: _fareFast,
                        isLoading: _isEstimateLoading,
                        isBest: true,
                        selected: selectedFare == FareType.fast,
                        onTap: () =>
                            setState(() => selectedFare = FareType.fast),
                      ),
                      const Gap(8),
                      _FareChip(
                        icon: PhosphorIconsFill.car,
                        label: '일반',
                        fare: _fareNormal,
                        isLoading: _isEstimateLoading,
                        selected: selectedFare == FareType.normal,
                        onTap: () =>
                            setState(() => selectedFare = FareType.normal),
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Row(
                  children: [
                    _PayChip(
                      icon: PhosphorIconsFill.currencyDollar,
                      label: '현금',
                      selected: selectedPayment == PaymentMethod.cash,
                      onTap: () =>
                          setState(() => selectedPayment = PaymentMethod.cash),
                    ),
                    const Gap(8),
                    _PayChip(
                      icon: PhosphorIconsFill.coins,
                      label: '마일',
                      selected: selectedPayment == PaymentMethod.mileage,
                      onTap: () => setState(
                        () => selectedPayment = PaymentMethod.mileage,
                      ),
                    ),
                    const Gap(8),
                    _PayChip(
                      icon: PhosphorIconsFill.creditCard,
                      label: '등록 카드',
                      selected:
                          selectedPayment == PaymentMethod.registeredCard,
                      onTap: () => setState(
                        () => selectedPayment = PaymentMethod.registeredCard,
                      ),
                    ),
                    const Gap(8),
                    _PayChip(
                      icon: PhosphorIconsFill.deviceMobile,
                      label: '앱결제',
                      selected: selectedPayment == PaymentMethod.appPayment,
                      onTap: () => setState(
                        () => selectedPayment = PaymentMethod.appPayment,
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isEstimateLoading
                        ? null
                        : () => widget.onOpenCallFlow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isEstimateLoading
                          ? '요금 계산 중...'
                          : '대리호출 (${_fmt(_selectedFareAmount)}원)',
                    ),
                  ),
                ),
              ] else ...[
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => widget.onOpenCallFlow(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('대리호출'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
