import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';

import 'api/api_client.dart';
import 'config/kakao_config.dart';
import 'config/payment_config.dart';
import 'routes/navigation.dart';
import 'services/app_quality_service.dart';
import 'services/push_notification_service.dart';
import 'widgets/auth_gate.dart';
import 'screens/call/call_map_screen.dart';
import 'screens/card/card_screen.dart';
import 'screens/complaint/complaint_screen.dart';
import 'screens/coupon/coupon_screen.dart';
import 'screens/event/event_screen.dart';
import 'screens/faq/faq_screen.dart';
import 'screens/gifticon/gifticon_orders_screen.dart';
import 'screens/gifticon/gifticon_shop_screen.dart';
import 'screens/home/main_scaffold.dart';
import 'screens/mileage/mileage_screen.dart';
import 'screens/notice/notice_screen.dart';
import 'screens/payment/toss_payment_screen.dart';
import 'screens/onboarding/permission_screen.dart';
import 'screens/auth/logged_out_screen.dart';
import 'screens/onboarding/phone_verify_screen.dart';
import 'screens/onboarding/referrer_screen.dart';
import 'screens/onboarding/terms_screen.dart';
import 'screens/qa/qa_screen.dart';
import 'screens/referrer/friend_invite_screen.dart';
import 'screens/referrer/referrer_status_screen.dart';
import 'screens/receipt/cash_receipt_screen.dart';
import 'screens/ride_history/ride_history_screen.dart';
import 'screens/settings/accident_penalty_screen.dart';
import 'screens/settings/account_delete_screen.dart';
import 'screens/settings/app_info_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/ride/ride_tracking_screen.dart';
import 'screens/withdrawal/withdrawal_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/security_service.dart';
import 'theme/app_theme.dart';
import 'theme/system_ui_config.dart';
import 'utils/payment_guard.dart';
import 'utils/responsive_layout.dart';
import 'widgets/connectivity_banner.dart';

void main() {
  AppQualityService.bootstrap(_startApp);
}

Future<void> _startApp() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: 'assets/env_defaults.env');
  }
  ApiClient.init();
  await SystemUiConfig.apply();

  final sec = await SecurityService.runSecurityCheck();
  if (SecurityService.shouldBlockApp(sec)) {
    runApp(SecurityBlockedApp(result: sec));
    return;
  }

  await Future.wait([
    Future(() async {
      try {
        await KakaoMapsFlutter.init(kakaoMapApiKey);
      } catch (_) {}
    }),
    Future(() async {
      try {
        await PushNotificationService.init();
      } catch (_) {}
    }),
  ]);

  runApp(const MyApp());
}

class SecurityBlockedApp extends StatelessWidget {
  const SecurityBlockedApp({super.key, required this.result});

  final SecurityCheckResult result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.security_rounded, size: 52),
                const SizedBox(height: 14),
                const Text(
                  '보안상의 이유로 앱을 실행할 수 없습니다.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '루팅/에뮬레이터/변조가 감지되었습니다.\n정상 기기에서 다시 실행해 주세요.',
                  style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('확인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      title: '일등대리',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: ResponsiveLayout.appTextScaler(context)),
          child: ConnectivityBannerScope(child: child),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/permission': (context) => const PermissionScreen(),
        '/terms': (context) => const TermsScreen(),
        '/logged-out': (context) => const LoggedOutScreen(),
        '/phone-verify': (context) {
          final isLogin =
              ModalRoute.of(context)?.settings.arguments == 'login';
          return PhoneVerifyScreen(isLogin: isLogin);
        },
        '/referrer': (context) {
          final isOnboarding = ModalRoute.of(context)?.settings.arguments == true;
          return ReferrerScreen(isOnboarding: isOnboarding);
        },
        '/home': (context) => const AuthGate(child: MainScaffold()),
        '/withdrawal': (context) => const WithdrawalScreen(),
        '/card': (context) => const CardScreen(),
        '/mileage': (context) => const MileageScreen(),
        '/gifticon-shop': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return GifticonShopScreen(
            initialBalance: args is int ? args : null,
          );
        },
        '/gifticon-orders': (context) => const GifticonOrdersScreen(),
        '/qa': (context) => const QaScreen(),
        '/notice': (context) => const NoticeScreen(),
        '/ride-history': (context) => const RideHistoryScreen(),
        '/complaint': (context) => const ComplaintScreen(),
        '/event': (context) => const EventScreen(),
        '/call-map': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is Map<String, dynamic>) {
            return CallMapScreen(
              initialPickup: args['pickup'] as String?,
              initialDropoff: args['dropoff'] as String?,
            );
          }
          return const CallMapScreen();
        },
        '/ride-tracking': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final rideId = args?['rideId'] as String? ?? '';
          if (rideId.isEmpty) {
            return const Scaffold(body: Center(child: Text('접수 정보가 없습니다.')));
          }
          return RideTrackingScreen(
            rideId: rideId,
            pickupLabel: args?['pickup'] as String?,
            dropoffLabel: args?['dropoff'] as String?,
          );
        },
        '/app-info': (context) => const AppInfoScreen(),
        '/notification-settings': (context) => const NotificationSettingsScreen(),
        '/accident-penalty': (context) => const AccidentPenaltyScreen(),
        '/coupon': (context) => const CouponScreen(),
        '/account-delete': (context) => const AccountDeleteScreen(),
        '/referrer-status': (context) => const ReferrerStatusScreen(),
        '/friend-invite': (context) => const FriendInviteScreen(),
        '/faq': (context) => const FaqScreen(),
        '/cash-receipt': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return CashReceiptScreen(
            rideId: args?['rideId'] as String?,
            amount: (args?['amount'] as num?)?.toInt(),
          );
        },
        '/payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          if (args == null) return const Scaffold(body: Center(child: Text('결제 정보 없음')));
          if (!paymentFeatureEnabled) {
            return _PaymentBlockedScreen(args: args);
          }
          final rideId = args['rideId'] as String? ?? '';
          final amount = (args['amount'] as num?)?.toInt() ?? 0;
          final orderName = args['orderName'] as String? ?? '대리운전 결제';
          return TossPaymentScreen(
            rideId: rideId,
            amount: amount,
            orderName: orderName,
          );
        },
      },
    );
  }
}

class _PaymentBlockedScreen extends StatefulWidget {
  const _PaymentBlockedScreen({required this.args});

  final Map<String, dynamic> args;

  @override
  State<_PaymentBlockedScreen> createState() => _PaymentBlockedScreenState();
}

class _PaymentBlockedScreenState extends State<_PaymentBlockedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showPaymentUnsupportedDialog(context);
      if (mounted) Navigator.pop(context, {'cancelled': true});
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

