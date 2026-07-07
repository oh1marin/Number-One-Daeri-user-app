import 'package:flutter/material.dart';

/// 기프티콘 브랜드/카테고리
enum GifticonCategory {
  coffee('메가커피'),
  chicken('BBQ');

  const GifticonCategory(this.label);
  final String label;
}

enum GifticonBrand {
  mega('메가MGC커피', Color(0xFFFFC107)),
  bbq('BBQ', Color(0xFFE8B004));

  const GifticonBrand(this.label, this.color);
  final String label;
  final Color color;
}

enum GifticonOrderStatus {
  pending('발송 준비'),
  sending('발송 중'),
  delivered('발송 완료'),
  failed('발송 실패');

  const GifticonOrderStatus(this.label);
  final String label;
}

/// 교환 가능 상품
class GifticonProduct {
  const GifticonProduct({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.mileagePrice,
    required this.brand,
    required this.category,
    this.faceValue,
    this.badge,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String subtitle;
  final int mileagePrice;
  final GifticonBrand brand;
  final GifticonCategory category;
  final int? faceValue;
  final String? badge;
  final String? imageUrl;

  String get brandLabel => brand.label;
  Color get brandColor => brand.color;
}

/// 교환 주문
class GifticonOrder {
  const GifticonOrder({
    required this.id,
    required this.productId,
    required this.productName,
    required this.brandLabel,
    required this.mileageUsed,
    required this.status,
    required this.orderedAt,
    this.pin,
    this.barcode,
    this.deliveredAt,
    this.phoneMasked,
  });

  final String id;
  final String productId;
  final String productName;
  final String brandLabel;
  final int mileageUsed;
  final GifticonOrderStatus status;
  final DateTime orderedAt;
  final String? pin;
  final String? barcode;
  final DateTime? deliveredAt;
  final String? phoneMasked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'brandLabel': brandLabel,
        'mileageUsed': mileageUsed,
        'status': status.name,
        'orderedAt': orderedAt.toIso8601String(),
        'pin': pin,
        'barcode': barcode,
        'deliveredAt': deliveredAt?.toIso8601String(),
        'phoneMasked': phoneMasked,
      };

  factory GifticonOrder.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] ?? 'pending').toString().toLowerCase();
    GifticonOrderStatus status;
    switch (statusRaw) {
      case 'completed':
      case 'delivered':
        status = GifticonOrderStatus.delivered;
        break;
      case 'sending':
      case 'processing':
        status = GifticonOrderStatus.sending;
        break;
      case 'failed':
        status = GifticonOrderStatus.failed;
        break;
      case 'pending':
        status = GifticonOrderStatus.pending;
        break;
      default:
        try {
          status = GifticonOrderStatus.values.byName(statusRaw);
        } catch (_) {
          status = GifticonOrderStatus.pending;
        }
    }

    int pickInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString().replaceAll(',', '')) ?? 0;
    }

    final orderedRaw =
        json['orderedAt'] ?? json['createdAt'] ?? json['ordered_at'];
    final deliveredRaw = json['deliveredAt'] ?? json['delivered_at'];

    return GifticonOrder(
      id: (json['id'] ?? json['orderId'] ?? '').toString(),
      productId: (json['productId'] ?? json['goodsCode'] ?? '').toString(),
      productName: (json['productName'] ?? json['name'] ?? json['goodsName'] ?? '')
          .toString(),
      brandLabel: (json['brandLabel'] ?? json['brandName'] ?? '').toString(),
      mileageUsed: pickInt(json['mileageUsed'] ?? json['price'] ?? json['amount']),
      status: status,
      orderedAt: DateTime.tryParse(orderedRaw?.toString() ?? '') ?? DateTime.now(),
      pin: json['pin']?.toString(),
      barcode: json['barcode']?.toString(),
      deliveredAt: deliveredRaw != null
          ? DateTime.tryParse(deliveredRaw.toString())
          : null,
      phoneMasked: json['phoneMasked']?.toString(),
    );
  }
}

class GifticonPurchaseResult {
  const GifticonPurchaseResult({
    required this.order,
    required this.remainingBalance,
  });

  final GifticonOrder order;
  final int remainingBalance;
}
