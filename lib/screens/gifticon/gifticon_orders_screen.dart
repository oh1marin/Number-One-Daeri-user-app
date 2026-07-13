import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../api/gifticon_api.dart';
import '../../models/gifticon.dart';
import '../../services/gifticon/gifticon_catalog.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/app_screen_widgets.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/load_error_view.dart';

/// 기프티콘 주문·발송 내역
class GifticonOrdersScreen extends StatefulWidget {
  const GifticonOrdersScreen({super.key});

  @override
  State<GifticonOrdersScreen> createState() => _GifticonOrdersScreenState();
}

class _GifticonOrdersScreenState extends State<GifticonOrdersScreen> {
  List<GifticonOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await GifticonApi.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = loadErrorMessage(e, fallback: '주문 내역을 불러오지 못했습니다.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityReconnectListener(
      onReconnect: _load,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceGrey,
        appBar: AppBar(
          title: const Text('기프티콘 주문내역'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _load,
            ),
          ],
        ),
        body: _loading
            ? const AppPageLoading()
            : _error != null
                ? LoadErrorView(message: _error!, onRetry: _load)
                : _orders.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            AppEmptyState(
                              icon: PhosphorIconsRegular.receipt,
                              title: '아직 교환한 기프티콘이 없습니다.',
                              subtitle: '교환몰에서 마일리지로 기프티콘을 받아보세요.',
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) => const Gap(12),
                          itemBuilder: (context, index) {
                            return _OrderCard(order: _orders[index]);
                          },
                        ),
                      ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final GifticonOrder order;

  Color get _statusColor {
    switch (order.status) {
      case GifticonOrderStatus.delivered:
        return const Color(0xFF2E7D32);
      case GifticonOrderStatus.sending:
        return const Color(0xFFF57C00);
      case GifticonOrderStatus.pending:
        return AppTheme.accentBlue;
      case GifticonOrderStatus.failed:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = GifticonCatalog.findById(order.productId);
    final brandColor = catalog?.brandColor ?? AppTheme.primaryDark;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                ),
                const Gap(8),
                Text(
                  order.status.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDateTime(order.orderedAt),
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.card_giftcard_rounded, color: brandColor, size: 22),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.brandLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: brandColor,
                        ),
                      ),
                      Text(
                        order.productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        '주문번호 ${order.id}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${formatKrw(order.mileageUsed)}P',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: _DeliveryTimeline(status: order.status, phone: order.phoneMasked),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y.$m.$d $h:$min';
  }
}

class _DeliveryTimeline extends StatelessWidget {
  const _DeliveryTimeline({required this.status, this.phone});

  final GifticonOrderStatus status;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('교환 접수', true),
      ('발송 준비', status != GifticonOrderStatus.pending),
      ('MMS 발송', status == GifticonOrderStatus.sending || status == GifticonOrderStatus.delivered),
      ('사용 가능', status == GifticonOrderStatus.delivered),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          phone != null ? '발송 번호 $phone' : '등록 휴대폰으로 발송',
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
        const Gap(10),
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: steps[i].$2 ? const Color(0xFF2E7D32) : AppTheme.borderGrey,
                  ),
                ),
              _StepDot(label: steps[i].$1, done: steps[i].$2),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.done});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: done ? const Color(0xFF2E7D32) : AppTheme.borderGrey,
            shape: BoxShape.circle,
          ),
        ),
        const Gap(4),
        SizedBox(
          width: 52,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: done ? AppTheme.primaryDark : AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
