import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../models/gifticon.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/gifticon/gifticon_widgets.dart';
import 'gifticon_orders_screen.dart';

/// 구매 완료 — PIN·발송 안내
class GifticonCompleteScreen extends StatelessWidget {
  const GifticonCompleteScreen({
    super.key,
    required this.order,
    required this.product,
    required this.remainingBalance,
  });

  final GifticonOrder order;
  final GifticonProduct product;
  final int remainingBalance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        title: const Text('교환 완료'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 44,
                    ),
                  ),
                  const Gap(16),
                  const Text(
                    '기프티콘 발급 완료',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    '주문번호 ${order.id}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const Gap(6),
                  Text(
                    '등록된 휴대폰(${order.phoneMasked ?? '010-****-****'})으로\n5분 이내 MMS 발송 예정',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.45),
                  ),
                  const Gap(24),
                  GifticonTicketCard(
                    productName: order.productName,
                    brandLabel: order.brandLabel,
                    brandColor: product.brandColor,
                    pin: order.pin,
                    barcode: order.barcode,
                    status: order.status,
                    phoneMasked: order.phoneMasked,
                  ),
                  const Gap(16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '교환 후 잔여 마일리지',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${formatKrw(remainingBalance)}P',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (order.pin != null) ...[
                    const Gap(12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.pin!));
                        showSuccessSnackBar(context, 'PIN 번호가 복사되었습니다.');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('PIN 번호 복사'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GifticonOrdersScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('주문내역'),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, remainingBalance),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('마일리지로'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
