import 'package:flutter/material.dart';

import '../../api/toss_payments_api.dart';
import '../../config/toss_config.dart';
import '../../config/payment_config.dart';
import '../../utils/payment_guard.dart';
import '../../utils/toss_payment_errors.dart';
import '../../widgets/portone_payment_shell.dart';
import '../../widgets/toss_billing_auth_webview.dart';

/// 토스 빌링 카드 등록 — requestBillingAuth → 서버 빌링키 발급
class CardRegisterPaymentScreen extends StatefulWidget {
  const CardRegisterPaymentScreen({super.key});

  @override
  State<CardRegisterPaymentScreen> createState() =>
      _CardRegisterPaymentScreenState();
}

class _CardRegisterPaymentScreenState extends State<CardRegisterPaymentScreen> {
  TossBillingConfig? _config;
  String? _loadError;
  bool _issuing = false;

  @override
  void initState() {
    super.initState();
    if (!paymentFeatureEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showPaymentUnsupportedDialog(context);
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await TossPaymentsApi.fetchBillingConfig();
      if (!isTossApiClientKey(config.clientKey)) {
        throw Exception(tossBillingContractRequiredMessage);
      }
      if (config.customerKey.trim().isEmpty) {
        throw Exception('고객 키를 확인할 수 없습니다. 다시 로그인해 주세요.');
      }
      if (!mounted) return;
      setState(() {
        _config = config;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = tossPaymentErrorMessage(
          e,
          fallback: '카드 등록 설정을 불러오지 못했습니다.',
        );
      });
    }
  }

  Future<void> _onAuthKey(String authKey) async {
    if (_issuing || !mounted) return;
    setState(() => _issuing = true);
    try {
      final issued = await TossPaymentsApi.issueBillingKey(authKey: authKey);
      if (!mounted) return;
      if (issued.billingKey.isEmpty) {
        throw Exception('빌링키를 받지 못했습니다.');
      }
      Navigator.pop(context, {
        'billingKey': issued.billingKey,
        'cardName': issued.cardName,
      });
    } catch (e) {
      if (!mounted) return;
      PortonePaymentShell.handlePaymentError(
        context,
        e,
        messageFor: (err) => tossPaymentErrorMessage(
          err,
          fallback: '카드 등록에 실패했습니다. 잠시 후 다시 시도해 주세요.',
        ),
      );
    } finally {
      if (mounted) setState(() => _issuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PortonePaymentShell(
      title: '카드 등록',
      body: Stack(
        children: [
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadConfig,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          else if (_config != null)
            TossBillingAuthWebView(
              clientKey: _config!.clientKey,
              customerKey: _config!.customerKey,
              onAuthKey: _onAuthKey,
              onError: (error) {
                PortonePaymentShell.handlePaymentError(
                  context,
                  error,
                  messageFor: (e) => tossPaymentErrorMessage(
                    e,
                    fallback: '카드 등록에 실패했습니다. 잠시 후 다시 시도해 주세요.',
                  ),
                );
              },
            ),
          if (_issuing)
            const ColoredBox(
              color: Color(0x88000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
