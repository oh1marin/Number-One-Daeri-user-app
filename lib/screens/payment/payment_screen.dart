import 'package:flutter/material.dart';
import 'package:portone_flutter_v2/portone_flutter_v2.dart';

import '../../config/portone_config.dart';
import '../../services/security_service.dart';
import '../../widgets/portone_billing_key_webview.dart';

/// 운행 완료 후 결제 화면 (카드 / 카카오페이 / 토스)
/// - 카드: requestIssueBillingKeyAndPay로 빌링키+결제 → billingKey, cardName 전달
/// - 카카오페이/토스: 기존 requestPayment 유지 (결제만)
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.rideId,
    required this.amount,
    required this.orderName,
    this.paymentMethod = PaymentScreenMethod.card,
  });

  final String rideId;
  final int amount;
  final String orderName;
  final PaymentScreenMethod paymentMethod;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    SecurityService.enableScreenshotProtection();
  }

  @override
  void dispose() {
    SecurityService.disableScreenshotProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isPortoneConfigured) {
      return Scaffold(
        appBar: AppBar(title: const Text('결제')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'PG 설정이 필요합니다.\nportone_config.dart 확인',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    final isCard = widget.paymentMethod == PaymentScreenMethod.card;
    final channelKey = widget.paymentMethod == PaymentScreenMethod.kakaopay
        ? portoneChannelKeyKakaopay
        : portoneChannelKey;
    final paymentId =
        'ride-${widget.rideId}-${DateTime.now().millisecondsSinceEpoch}';

    if (isCard) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          title: const Text('카드 결제', style: TextStyle(color: Colors.black87)),
        ),
        body: PortoneBillingKeyWebView(
          mode: PortoneBillingKeyWebView.modeBillingKeyAndPay,
          storeId: portoneStoreId,
          channelKey: channelKey,
          appScheme: portoneAppScheme,
          useTestChannel: portoneUseTestChannel,
          paymentId: paymentId,
          orderName: widget.orderName,
          amount: widget.amount,
          initialChild: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('결제창 불러오는 중...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          onResult: (raw) {
            if (context.mounted) {
              Navigator.pop(context, {
                'success': true,
                'transactionId': raw['txId'] ?? raw['transactionId'],
                'paymentId': raw['paymentId'],
                'rawResponse': raw,
                'billingKey': raw['billingKey'],
                'cardName': raw['cardName'],
              });
            }
          },
          onError: (error) {
            debugPrint('결제 오류: $error');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('결제 실패: ${error.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    }

    final payMethod = widget.paymentMethod == PaymentScreenMethod.kakaopay
        ? PaymentPayMethod.easyPay
        : PaymentPayMethod.card;
    final pg = widget.paymentMethod == PaymentScreenMethod.kakaopay
        ? PGCompany.kakaopay
        : PGCompany.tosspayments;
    final request = PaymentRequest(
      storeId: portoneStoreId,
      paymentId: paymentId,
      orderName: widget.orderName,
      totalAmount: widget.amount,
      currency: PaymentCurrency.KRW,
      channelKey: channelKey,
      payMethod: payMethod,
      appScheme: portoneAppScheme,
      pg: pg,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: Text(
          widget.paymentMethod == PaymentScreenMethod.kakaopay
              ? '카카오페이 결제'
              : '토스 결제',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
      body: PortonePayment(
        data: request,
        initialChild: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('결제창 불러오는 중...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        callback: (PaymentResponse result) {
          if (context.mounted) {
            final json = result.toJson();
            Navigator.pop(context, {
              'success': true,
              'transactionId': result.transactionId,
              'paymentId': result.paymentId,
              'rawResponse': json,
              'billingKey': json['billingKey'] as String?,
              'cardName': json['cardName'] as String?,
            });
          }
        },
        onError: (error) {
          debugPrint('결제 오류: $error');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('결제 실패: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}

enum PaymentScreenMethod { card, kakaopay, toss }
