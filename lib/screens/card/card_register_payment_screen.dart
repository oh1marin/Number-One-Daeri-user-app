import 'package:flutter/material.dart';

import '../../config/portone_config.dart';
import '../../widgets/portone_billing_key_webview.dart';

/// 카드 등록용 100원 인증 (requestIssueBillingKey) — 빌링키를 cardToken으로 저장
class CardRegisterPaymentScreen extends StatelessWidget {
  const CardRegisterPaymentScreen({
    super.key,
    required this.cardName,
    required this.expiryDate,
    required this.option,
  });

  final String cardName;
  final String expiryDate;
  final String option;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('카드 등록', style: TextStyle(color: Colors.black87, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
      body: PortoneBillingKeyWebView(
        mode: PortoneBillingKeyWebView.modeBillingKey,
        storeId: portoneStoreId,
        channelKey: portoneChannelKey,
        appScheme: portoneAppScheme,
        useTestChannel: portoneUseTestChannel,
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
            final txId = raw['txId'] ?? raw['transactionId'];
            Navigator.pop(context, {
              'transactionId': txId?.toString(),
              'paymentId': raw['paymentId']?.toString(),
              'billingKey': raw['billingKey']?.toString(),
              'cardName': raw['cardName']?.toString(),
              'rawResponse': raw,
            });
          }
        },
        onError: (error) {
          debugPrint('PortOne 빌링키 발급 오류: $error');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('카드 등록 실패: ${error.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }
}
