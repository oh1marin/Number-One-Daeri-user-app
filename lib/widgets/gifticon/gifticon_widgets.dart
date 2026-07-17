import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../models/gifticon.dart';
import '../../config/media_url.dart';
import '../../theme/app_theme.dart';
import '../../utils/user_friendly_text.dart';
import '../app_network_image.dart';
import '../mileage_gifticon_banner.dart';
import '../signup_bonus_mileage_notice.dart';

/// 기프티콘 상단 잔액 배너
class GifticonBalanceHeader extends StatelessWidget {
  const GifticonBalanceHeader({
    super.key,
    required this.balance,
    this.gifticonSpendable,
    this.onOrdersTap,
    this.horizontalPadding = 20,
  });

  final int balance;
  final int? gifticonSpendable;
  final VoidCallback? onOrdersTap;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return MileageGifticonBackgroundCard(
      margin: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 6),
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      imageAlignment: Alignment.center,
      gradient: LinearGradient(
        colors: [
          const Color(0xFF2E7D32).withValues(alpha: 0.57),
          const Color(0xFF1B5E20).withValues(alpha: 0.33),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 14),
                    Gap(4),
                    Text(
                      '마일리지 기프티콘',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (onOrdersTap != null)
                TextButton.icon(
                  onPressed: onOrdersTap,
                  icon: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 16),
                  label: const Text(
                    '주문내역',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          const Gap(10),
          Text(
            gifticonSpendable != null && gifticonSpendable! < balance
                ? '보유 마일리지'
                : '교환 가능 마일리지',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Gap(2),
          Text(
            '${formatKrw(balance)}P',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (gifticonSpendable != null && gifticonSpendable! < balance) ...[
            const Gap(8),
            Text(
              '기프티콘 교환 가능 ${formatKrw(gifticonSpendable!)}P',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(4),
            Text(
              kSignupBonusMileageNotice,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ] else ...[
            const Gap(6),
            Text(
              '1P = 1원 · 교환 시 즉시 차감 · 기프티콘은 문자(MMS)로 발송',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

/// 카테고리 칩
class GifticonCategoryChips extends StatelessWidget {
  const GifticonCategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.horizontalPadding = 20,
  });

  final GifticonCategory? selected;
  final ValueChanged<GifticonCategory?> onSelected;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: [
          _Chip(
            label: '전체',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          ...GifticonCategory.values.map(
            (c) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _Chip(
                label: c.label,
                selected: selected == c,
                onTap: () => onSelected(c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primaryDark : AppTheme.borderGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.primaryDark,
          ),
        ),
      ),
    );
  }
}

/// 상품 카드 — 리스트(1열) / 그리드(2열) 공통
class GifticonProductCard extends StatelessWidget {
  const GifticonProductCard({
    super.key,
    required this.product,
    required this.canAfford,
    required this.onTap,
    this.compact = false,
  });

  final GifticonProduct product;
  final bool canAfford;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompactCard();
    return _buildListCard();
  }

  Widget _buildCompactCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: canAfford ? AppTheme.borderGrey : Colors.red.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GifticonProductImage(
                  product: product,
                  fit: BoxFit.contain,
                  imagePadding: const EdgeInsets.all(10),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: product.brandColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.brandLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: product.brandColor.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    const Gap(3),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                        height: 1.2,
                      ),
                    ),
                    if (product.subtitle.isNotEmpty) ...[
                      const Gap(1),
                      Text(
                        product.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const Gap(4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${formatKrw(product.mileagePrice)}P',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: canAfford
                                ? const Color(0xFF2E7D32)
                                : Colors.red.shade400,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (!canAfford) ...[
                          const Gap(4),
                          Text(
                            '부족',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.red.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderGrey),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GifticonProductImage(
                product: product,
                height: 188,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryDark,
                        height: 1.3,
                      ),
                    ),
                    const Gap(12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '교환 가격',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Gap(2),
                            Text(
                              '${formatKrw(product.mileagePrice)}P',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: canAfford
                                    ? const Color(0xFF2E7D32)
                                    : Colors.red.shade400,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (!canAfford)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Text(
                              '마일리지 부족',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Gap(14),
                    Container(
                      width: double.infinity,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: canAfford
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        canAfford
                            ? '${formatKrw(product.mileagePrice)}P 교환하기'
                            : '마일리지 충전 후 교환',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 상품 이미지 영역 (목록·상세 공통)
class GifticonProductImage extends StatelessWidget {
  const GifticonProductImage({
    super.key,
    required this.product,
    this.height,
    this.fit = BoxFit.cover,
    this.imagePadding = EdgeInsets.zero,
    this.borderRadius,
  });

  final GifticonProduct product;
  final double? height;
  final BoxFit fit;
  final EdgeInsetsGeometry imagePadding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final img = resolveMediaUrl(product.imageUrl);
    final radius = borderRadius ?? BorderRadius.circular(16);
    final fallback = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: product.brandColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: product.brandColor.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        _brandIcon(product.brand),
        color: Colors.white,
        size: 34,
      ),
    );

    Widget imageBody = img != null
        ? SizedBox.expand(
            child: AppNetworkImage(
              url: img,
              fit: fit,
              alignment: Alignment.center,
              errorWidget: Center(child: fallback),
            ),
          )
        : Center(child: fallback);

    if (imagePadding != EdgeInsets.zero) {
      imageBody = Padding(padding: imagePadding, child: imageBody);
    }

    final surface = Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            product.brandColor.withValues(alpha: 0.12),
            product.brandColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageBody,
      ),
    );

    return Stack(
      children: [
        surface,
        if (product.badge != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _brandIcon(GifticonBrand brand) {
    switch (brand) {
      case GifticonBrand.mega:
        return Icons.local_cafe_rounded;
      case GifticonBrand.bbq:
        return Icons.restaurant_rounded;
    }
  }
}

/// 기프티콘 티켓 비주얼 (완료·주문 상세)
class GifticonTicketCard extends StatelessWidget {
  const GifticonTicketCard({
    super.key,
    required this.productName,
    required this.brandLabel,
    required this.brandColor,
    this.pin,
    this.barcode,
    this.status,
    this.phoneMasked,
  });

  final String productName;
  final String brandLabel;
  final Color brandColor;
  final String? pin;
  final String? barcode;
  final GifticonOrderStatus? status;
  final String? phoneMasked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandColor, brandColor.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 20),
                    const Gap(6),
                    Text(
                      brandLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (status != null) _StatusPill(status: status!),
                  ],
                ),
                const Gap(12),
                Text(
                  productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                if (phoneMasked != null) ...[
                  const Gap(8),
                  Text(
                    '발송 번호 $phoneMasked',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (barcode != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderGrey),
                    ),
                    child: Column(
                      children: [
                        _BarcodeLines(),
                        const Gap(8),
                        Text(
                          _formatBarcode(barcode!),
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            letterSpacing: 2,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                ],
                if (pin != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PIN 번호',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          _formatPin(pin!),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPin(String raw) {
    final d = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (d.length <= 4) return d;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  String _formatBarcode(String raw) {
    final d = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (d.length <= 4) return d;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final GifticonOrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (status) {
      case GifticonOrderStatus.delivered:
        bg = Colors.white.withValues(alpha: 0.25);
        fg = Colors.white;
      case GifticonOrderStatus.sending:
        bg = Colors.amber.shade100;
        fg = Colors.amber.shade900;
      case GifticonOrderStatus.pending:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
      case GifticonOrderStatus.failed:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg),
      ),
    );
  }
}

class _BarcodeLines extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(28, (i) {
          final w = (i % 3 == 0) ? 3.0 : (i % 2 == 0 ? 2.0 : 1.0);
          return Container(
            width: w,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            color: i.isEven ? Colors.black87 : Colors.transparent,
          );
        }),
      ),
    );
  }
}

/// 마일리지 차감 요약 (확인 화면)
class GifticonMileageSummary extends StatelessWidget {
  const GifticonMileageSummary({
    super.key,
    required this.current,
    required this.deduct,
    this.currentLabel = '현재 마일리지',
  });

  final int current;
  final int deduct;
  final String currentLabel;

  int get remaining => current - deduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        children: [
          _row(currentLabel, '${formatKrw(current)}P', AppTheme.primaryDark),
          const Gap(10),
          _row('차감 마일리지', '- ${formatKrw(deduct)}P', const Color(0xFFE53935)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _row('교환 후 잔여', '${formatKrw(remaining)}P', const Color(0xFF2E7D32), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 17 : 15,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
