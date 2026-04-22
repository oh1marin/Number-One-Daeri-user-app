import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_maps_flutter/kakao_maps_flutter.dart';

import 'api/api_client.dart';
import 'config/kakao_config.dart';
import 'routes/navigation.dart';
import 'services/push_notification_service.dart';
import 'screens/call/call_map_screen.dart';
import 'screens/card/card_screen.dart';
import 'screens/complaint/complaint_screen.dart';
import 'screens/coupon/coupon_screen.dart';
import 'screens/event/event_screen.dart';
import 'screens/faq/faq_screen.dart';
import 'screens/home/main_scaffold.dart';
import 'screens/mileage/mileage_screen.dart';
import 'screens/notice/notice_screen.dart';
import 'screens/payment/payment_screen.dart';
import 'screens/onboarding/permission_screen.dart';
import 'screens/onboarding/phone_verify_screen.dart';
import 'screens/onboarding/referrer_screen.dart';
import 'screens/onboarding/terms_screen.dart';
import 'screens/qa/qa_screen.dart';
import 'screens/referrer/referrer_status_screen.dart';
import 'screens/receipt/cash_receipt_screen.dart';
import 'screens/ride_history/ride_history_screen.dart';
import 'screens/settings/accident_penalty_screen.dart';
import 'screens/settings/account_delete_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/withdrawal/withdrawal_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/security_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    await dotenv.load(fileName: 'assets/env_defaults.env');
  }
  ApiClient.init();
  // 앱 시작 시 보안 검사 (Root/탈옥, 에뮬, 변조 등)
  final secResult = await SecurityService.runSecurityCheck();
  if (!secResult.secure) {
    debugPrint('보안 경고: root=${secResult.isRooted} emulator=${secResult.isEmulator} '
        'tampered=${secResult.isTampered} screenRecord=${secResult.isScreenBeingRecorded}');
    // 필요 시 여기서 앱 종료 또는 사용자 알림
  }
  ApiClient.onAuthRequired = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/phone-verify',
      (route) => false,
    );
  };
  try {
    await KakaoMapsFlutter.init(kakaoMapApiKey);
  } catch (_) {}
  try {
    await PushNotificationService.init();
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '일등대리',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/permission': (context) => const PermissionScreen(),
        '/terms': (context) => const TermsScreen(),
        '/phone-verify': (context) => const PhoneVerifyScreen(),
        '/referrer': (context) {
          final isOnboarding = ModalRoute.of(context)?.settings.arguments == true;
          return ReferrerScreen(isOnboarding: isOnboarding);
        },
        '/home': (context) => const MainScaffold(),
        '/withdrawal': (context) => const WithdrawalScreen(),
        '/card': (context) => const CardScreen(),
        '/mileage': (context) => const MileageScreen(),
        '/qa': (context) => const QaScreen(),
        '/notice': (context) => const NoticeScreen(),
        '/ride-history': (context) => const RideHistoryScreen(),
        '/complaint': (context) => const ComplaintScreen(),
        '/event': (context) => const EventScreen(),
        '/call-map': (context) => const CallMapScreen(),
        '/notification-settings': (context) => const NotificationSettingsScreen(),
        '/accident-penalty': (context) => const AccidentPenaltyScreen(),
        '/coupon': (context) => const CouponScreen(),
        '/account-delete': (context) => const AccountDeleteScreen(),
        '/referrer-status': (context) => const ReferrerStatusScreen(),
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
          final pm = args['kakaopay'] == true
              ? PaymentScreenMethod.kakaopay
              : args['toss'] == true
                  ? PaymentScreenMethod.toss
                  : PaymentScreenMethod.card;
          return PaymentScreen(
            rideId: args['rideId'] as String? ?? '',
            amount: (args['amount'] as num?)?.toInt() ?? 0,
            orderName: args['orderName'] as String? ?? '대리운전 결제',
            paymentMethod: pm,
          );
        },
      },
    );
  }
}

