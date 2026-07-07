/// 앱 업데이트 · 스토어 링크
class AppUpdateConfig {
  AppUpdateConfig._();

  static const androidPackageId = 'com.numberonedaeri.app';

  static const playStoreHttpsUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  static const playStoreMarketUrl = 'market://details?id=$androidPackageId';
}
