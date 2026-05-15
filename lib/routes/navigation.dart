import 'package:flutter/material.dart';

/// Global navigator key for push deep-links and auth redirects.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Allows screens to refresh when returning via Navigator.pop().
final RouteObserver<PageRoute<dynamic>> routeObserver = RouteObserver<PageRoute<dynamic>>();

