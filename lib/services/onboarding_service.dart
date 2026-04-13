import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _keyPermissionDone = 'onboarding_permission_done';
  static const _keyTermsDone = 'onboarding_terms_done';
  static const _keyReferrerDone = 'onboarding_referrer_done';
  static const _keyOnboardingComplete = 'onboarding_complete';

  static Future<bool> isPermissionDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPermissionDone) ?? false;
  }

  static Future<void> setPermissionDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPermissionDone, true);
  }

  static Future<bool> isTermsDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTermsDone) ?? false;
  }

  static Future<void> setTermsDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTermsDone, true);
  }

  static Future<bool> isReferrerDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReferrerDone) ?? false;
  }

  static Future<void> setReferrerDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReferrerDone, true);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingComplete) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, true);
  }

  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPermissionDone);
    await prefs.remove(_keyTermsDone);
    await prefs.remove(_keyReferrerDone);
    await prefs.remove(_keyOnboardingComplete);
  }
}
