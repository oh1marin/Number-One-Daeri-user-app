import 'package:flutter/material.dart';

import '../screens/attendance/attendance_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/customers/customer_list_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/drivers/driver_detail_screen.dart';
import '../screens/drivers/driver_list_screen.dart';
import '../screens/invoices/invoice_list_screen.dart';
import '../screens/rides/ride_list_screen.dart';
import '../screens/inquiries/inquiry_list_screen.dart';
import '../screens/settings/fare_settings_screen.dart';

class AppRouter {
  static const login = '/login';
  static const register = '/register';
  static const dashboard = '/';
  static const customerList = '/customers';
  static const customerDetail = '/customer-detail';
  static const driverList = '/drivers';
  static const driverDetail = '/driver-detail';
  static const rideList = '/rides';
  static const attendance = '/attendance';
  static const invoiceList = '/invoices';
  static const fareSettings = '/settings/fares';
  static const inquiryList = '/inquiries';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case customerList:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      case customerDetail:
        final id = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => CustomerDetailScreen(customerId: id),
        );
      case driverList:
        return MaterialPageRoute(builder: (_) => const DriverListScreen());
      case driverDetail:
        final id = settings.arguments as String? ?? '';
        return MaterialPageRoute(
          builder: (_) => DriverDetailScreen(driverId: id),
        );
      case rideList:
        return MaterialPageRoute(builder: (_) => const RideListScreen());
      case attendance:
        return MaterialPageRoute(builder: (_) => const AttendanceScreen());
      case invoiceList:
        return MaterialPageRoute(builder: (_) => const InvoiceListScreen());
      case fareSettings:
        return MaterialPageRoute(builder: (_) => const FareSettingsScreen());
      case inquiryList:
        return MaterialPageRoute(builder: (_) => const InquiryListScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Not found: ${settings.name}')),
          ),
        );
    }
  }
}
