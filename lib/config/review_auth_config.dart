/// App Store / Play 심사·테스트용 마스터 계정 (BE `reviewMasterAuth.ts`와 동일)
class ReviewAuthConfig {
  ReviewAuthConfig._();

  static const masterPhone = '01012345678';
  static const masterOtp = '111111';

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.startsWith('82') && digits.length >= 12) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 10 && digits.startsWith('10')) {
      return '0$digits';
    }
    return digits;
  }

  static bool isReviewMasterPhone(String phone) {
    return normalizePhone(phone) == masterPhone;
  }

  static bool matchesReviewCredentials(String phone, String code) {
    return isReviewMasterPhone(phone) && code.trim() == masterOtp;
  }
}
