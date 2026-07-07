/// 앱 추천 공유 문구 (추천인 API 없음 — 전화·혜택 중심)
class AppShareText {
  AppShareText._();

  static const hotline = '010-2184-8822';
  static const playStoreHint =
      '구글 플레이에서 「일등대리」를 검색해 설치해 주세요.';

  static String build() {
    return [
      '일등대리 $hotline — 24시간 대리운전 앱 접수!',
      '신규 가입 혜택·친구 추천 이벤트 진행 중 🚗',
      playStoreHint,
      '문의: $hotline',
    ].join('\n');
  }
}
