import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_info.dart';
import 'package:tosspayments_widget_sdk_flutter/model/payment_widget_options.dart';
import 'package:tosspayments_widget_sdk_flutter/model/tosspayments_result.dart';
import 'package:tosspayments_widget_sdk_flutter/payment_widget.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/agreement.dart';
import 'package:tosspayments_widget_sdk_flutter/widgets/payment_method.dart';

import '../../api/card_payments_api.dart';
import '../../api/toss_payments_api.dart';
import '../../config/toss_config.dart';
import '../../services/auth_service.dart';
import '../../services/security_service.dart';
import '../../config/payment_config.dart';
import '../../utils/payment_guard.dart';
import '../../utils/toss_payment_errors.dart';

/// 토스페이먼츠 결제위젯 — 카드 / 카카오페이 / 토스페이
/// 1) 서버 prepare → 2) 위젯 렌더 → 3) 결제 → 4) 서버 confirm
class TossPaymentScreen extends StatefulWidget {
  const TossPaymentScreen({
    super.key,
    required this.rideId,
    required this.amount,
    this.orderName,
  });

  final String rideId;
  final int amount;
  final String? orderName;

  @override
  State<TossPaymentScreen> createState() => _TossPaymentScreenState();
}

class _TossPaymentScreenState extends State<TossPaymentScreen> {
  static const _methodsSelector = 'ride_payment_methods';
  static const _agreementSelector = 'ride_payment_agreement';
  static const _widgetRenderTimeout = Duration(seconds: 30);

  PaymentWidget? _paymentWidget;
  AgreementWidgetControl? _agreementControl;

  TossPrepareData? _prepare;
  String? _loadError;
  bool _loading = true;
  bool _paying = false;
  bool _widgetsReady = false;
  bool _widgetInitStarted = false;

  StreamSubscription<Uri>? _linkSub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    if (!paymentFeatureEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showPaymentUnsupportedDialog(context);
        if (mounted) Navigator.pop(context, {'cancelled': true});
      });
      return;
    }
    SecurityService.enableScreenshotProtection();
    _listenAppLinks();
    _bootstrap();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    SecurityService.disableScreenshotProtection();
    super.dispose();
  }

  void _listenAppLinks() {
    _linkSub = _appLinks.uriLinkStream.listen(_onAppLink);
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _onAppLink(uri);
    });
  }

  void _onAppLink(Uri uri) {
    if (uri.scheme != 'numberonedarri') return;
    final redirect = uri.queryParameters['url'];
    if (redirect == null || redirect.isEmpty) return;
    _paymentWidget?.handlePaymentRedirect(redirect);
  }

  Future<void> _bootstrap() async {
    if (widget.amount <= 0) {
      if (!mounted) return;
      setState(() {
        _loadError = '결제 금액이 올바르지 않습니다. 요금을 확인한 뒤 다시 시도해 주세요.';
        _loading = false;
      });
      return;
    }

    try {
      final prepare = await TossPaymentsApi.prepare(
        rideId: widget.rideId,
        amount: widget.amount,
        idempotencyKey: TossPaymentsApi.prepareIdempotencyKeyForRide(widget.rideId),
      );

      var clientKey = prepare.clientKey?.trim() ?? '';
      if (clientKey.isEmpty) clientKey = tossWidgetClientKeyFallback;
      if (clientKey.isEmpty) {
        clientKey = await TossPaymentsApi.fetchClientKey() ?? '';
      }
      if (!isTossWidgetClientKey(clientKey)) {
        throw Exception(tossWidgetKeySetupMessage());
      }

      final customerKey = await _resolveCustomerKey();
      final paymentWidget = PaymentWidget(
        clientKey: clientKey,
        customerKey: customerKey,
      );

      if (!mounted) return;
      setState(() {
        _prepare = prepare;
        _paymentWidget = paymentWidget;
        _loading = false;
        _widgetsReady = false;
        _widgetInitStarted = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = tossPaymentErrorMessage(e, fallback: '결제 준비에 실패했습니다.');
        _loading = false;
      });
    }
  }

  Future<String> _resolveCustomerKey() async {
    try {
      final me = await AuthService.getMe();
      if (me != null && me.id.isNotEmpty) {
        return me.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      }
    } catch (_) {}
    return 'ride_${widget.rideId}'.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  void _scheduleWidgetInit() {
    if (_widgetInitStarted || _widgetsReady || _paymentWidget == null) return;
    _widgetInitStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWidgets());
  }

  Future<void> _initWidgets() async {
    final widget_ = _paymentWidget;
    final prepare = _prepare;
    if (widget_ == null || prepare == null || _widgetsReady) return;

    try {
      await widget_
          .renderPaymentMethods(
            selector: _methodsSelector,
            amount: Amount(
              value: prepare.amount,
              currency: Currency.KRW,
              country: 'KR',
            ),
            options: RenderPaymentMethodsOptions(variantKey: 'DEFAULT'),
          )
          .timeout(_widgetRenderTimeout);

      final agreement = await widget_
          .renderAgreement(
            selector: _agreementSelector,
            options: RenderAgreementOptions(variantKey: 'AGREEMENT'),
          )
          .timeout(_widgetRenderTimeout);

      if (!mounted) return;
      setState(() {
        _agreementControl = agreement;
        _widgetsReady = true;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _loadError = '결제창 로딩이 지연되고 있습니다. 네트워크를 확인한 뒤 다시 시도해 주세요.';
        _widgetInitStarted = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = _messageFromWidgetError(e);
        _widgetInitStarted = false;
      });
    }
  }

  String _messageFromWidgetError(Object e) {
    if (e is Fail) {
      return e.errorMessage.isNotEmpty
          ? e.errorMessage
          : tossPaymentErrorMessage(Exception(e.errorCode));
    }
    return tossPaymentErrorMessage(
      e,
      fallback: '결제창을 불러오지 못했습니다. 결제위젯 연동 키(test_gck_)를 확인해 주세요.',
    );
  }

  Future<void> _pay() async {
    final widget_ = _paymentWidget;
    final prepare = _prepare;
    if (widget_ == null || prepare == null || _paying || !_widgetsReady) return;

    final agreed = await _agreementControl?.getAgreementStatus();
    if (agreed != null && !agreed.agreedRequiredTerms) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('필수 약관에 동의해 주세요.')),
        );
      }
      return;
    }

    setState(() => _paying = true);
    try {
      final result = await widget_.requestPayment(
        paymentInfo: PaymentInfo(
          orderId: prepare.orderId,
          orderName: prepare.orderName.isNotEmpty
              ? prepare.orderName
              : (widget.orderName ?? '대리운전 이용료'),
          appScheme: tossAppScheme,
        ),
      );

      if (!mounted) return;

      if (result.fail != null) {
        final fail = result.fail!;
        if (fail.errorCode == 'USER_CANCEL' ||
            fail.errorMessage.contains('취소') ||
            fail.errorMessage.contains('cancel')) {
          Navigator.pop(context, {'cancelled': true});
          return;
        }
        Navigator.pop(context, {
          'success': false,
          'message': fail.errorMessage.isNotEmpty
              ? fail.errorMessage
              : '결제에 실패했습니다.',
        });
        return;
      }

      final String paymentKey;
      final String orderId;
      final int amount;

      if (result.success != null) {
        paymentKey = result.success!.paymentKey;
        orderId = result.success!.orderId;
        amount = result.success!.amount.toInt();
      } else if (result.pending != null) {
        paymentKey = result.pending!.paymentKey;
        orderId = result.pending!.orderId;
        amount = result.pending!.amount.toInt();
      } else {
        Navigator.pop(context, {
          'success': false,
          'message': '결제 결과를 확인할 수 없습니다.',
        });
        return;
      }

      await TossPaymentsApi.confirm(
        paymentKey: paymentKey,
        orderId: orderId,
        amount: amount,
        idempotencyKey: PaymentsApi.idempotencyKeyForRide(widget.rideId),
      );

      if (!mounted) return;
      Navigator.pop(context, {
        'success': true,
        'paymentKey': paymentKey,
        'orderId': orderId,
        'amount': amount,
      });
    } on DioException catch (e) {
      if (!mounted) return;
      Navigator.pop(context, {
        'success': false,
        'message': tossPaymentErrorMessage(e, fallback: '결제 승인에 실패했습니다.'),
      });
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context, {
        'success': false,
        'message': tossPaymentErrorMessage(e, fallback: '결제에 실패했습니다.'),
      });
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _retryAll() {
    setState(() {
      _loadError = null;
      _loading = true;
      _widgetsReady = false;
      _widgetInitStarted = false;
      _paymentWidget = null;
      _prepare = null;
      _agreementControl = null;
    });
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('결제')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('결제 준비 중...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_loadError != null || _paymentWidget == null || _prepare == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('결제')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _loadError ?? '결제를 시작할 수 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _retryAll,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _scheduleWidgetInit();

    final pw = _paymentWidget!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _paying ? null : () => Navigator.pop(context, {'cancelled': true}),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Text(
                        '${_prepare!.amount}원',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _prepare!.orderName,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 16),
                      // SDK가 updateHeight로 실제 높이를 보고함 — 고정 높이 시 테스트 배너·약관 UI가 잘림
                      PaymentMethodWidget(
                        paymentWidget: pw,
                        selector: _methodsSelector,
                      ),
                      const SizedBox(height: 12),
                      AgreementWidget(
                        paymentWidget: pw,
                        selector: _agreementSelector,
                      ),
                    ],
                  ),
                  if (!_widgetsReady)
                    const ColoredBox(
                      color: Color(0xE6FFFFFF),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text(
                              '결제수단 불러오는 중...',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: (_widgetsReady && !_paying) ? _pay : null,
                  child: _paying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('${_prepare!.amount}원 결제하기'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
