import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../api/gifticon_api.dart';
import '../../models/gifticon.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/user_friendly_text.dart';
import '../../widgets/gifticon/gifticon_widgets.dart';
import 'gifticon_complete_screen.dart';

/// 구매 확인 — 마일리지 차감 안내
class GifticonConfirmScreen extends StatefulWidget {
  const GifticonConfirmScreen({
    super.key,
    required this.product,
    required this.currentBalance,
    required this.gifticonSpendable,
  });

  final GifticonProduct product;
  final int currentBalance;
  final int gifticonSpendable;

  @override
  State<GifticonConfirmScreen> createState() => _GifticonConfirmScreenState();
}

class _GifticonConfirmScreenState extends State<GifticonConfirmScreen> {
  bool _submitting = false;

  bool get _canAfford => widget.gifticonSpendable >= widget.product.mileagePrice;

  bool get _hasBalanceButSignupLocked =>
      widget.currentBalance >= widget.product.mileagePrice && !_canAfford;

  Future<void> _confirm() async {
    if (!_canAfford || _submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await GifticonApi.purchase(
        product: widget.product,
        currentBalance: widget.currentBalance,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GifticonCompleteScreen(
            order: result.order,
            product: widget.product,
            remainingBalance: result.remainingBalance,
          ),
        ),
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(title: const Text('교환 확인')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GifticonProductImage(
                          product: p,
                          height: 220,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryDark,
                                  height: 1.3,
                                ),
                              ),
                              const Gap(10),
                              Row(
                                children: [
                                  Text(
                                    '${formatKrw(p.mileagePrice)}P',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const Gap(6),
                                  Text(
                                    '교환',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                  GifticonMileageSummary(
                    current: widget.gifticonSpendable,
                    deduct: p.mileagePrice,
                    currentLabel: '기프티콘 교환 가능',
                  ),
                  const Gap(16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE082)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '마일리지 차감 후 구매됩니다',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        Gap(8),
                        Text(
                          '· 확인 시 마일리지가 즉시 차감됩니다.\n'
                          '· 기프티콘은 등록된 휴대폰 번호로 MMS 발송됩니다.\n'
                          '· 발송까지 최대 5분 소요될 수 있습니다.\n'
                          '· 교환 후 취소·환불은 불가합니다.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5D4037),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasBalanceButSignupLocked) ...[
                    const Gap(16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        '가입 보너스 ${formatKrw(widget.currentBalance - widget.gifticonSpendable)}P는 '
                        '대리운전에만 사용할 수 있습니다.\n'
                        '대리 이용 후 적립된 마일리지로 기프티콘을 교환해 주세요.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ] else if (!_canAfford) ...[
                    const Gap(16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        '교환 가능 마일리지가 ${formatKrw(p.mileagePrice - widget.gifticonSpendable)}P 부족합니다.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
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
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_canAfford && !_submitting) ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          '${formatKrw(p.mileagePrice)}P 교환하기',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
