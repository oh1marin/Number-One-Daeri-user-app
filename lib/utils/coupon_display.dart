/// 쿠폰 `code`(예: STARBUCKS_5000)를 사용자에게 보여줄 짧은 제목으로 바꿉니다.
class CouponDisplay {
  CouponDisplay._();

  static const Map<String, String> _brandByToken = {
    'STARBUCKS': '스타벅스',
    'STARBUCK': '스타벅스',
    'KYOCHON': '교촌치킨',
    'KYOCHONCHICKEN': '교촌치킨',
    'BBQ': 'BBQ',
    'BHC': 'BHC',
    'MCDONALDS': '맥도날드',
    'MCD': '맥도날드',
    'LOTTERIA': '롯데리아',
    'SUBWAY': '써브웨이',
    'BASKIN': '배스킨라빈스',
    'BASKINROBBINS': '배스킨라빈스',
    'BR': '배스킨라빈스',
    'TWOSOME': '투썸플레이스',
    'TWOSOMEPLACE': '투썸플레이스',
    'MEGA': '메가커피',
    'MEGACOFFEE': '메가커피',
    'COMPOSE': '컴포즈커피',
    'COMPOSECOFFEE': '컴포즈커피',
    'GIFT': '기프트',
    'VOUCHER': '상품권',
  };

  /// [rawCode]가 비어 있으면 `쿠폰`, 알 수 없으면 언더스코어·끝 숫자만 정리해 `OOO 쿠폰` 형태.
  static String titleFromCode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return '쿠폰';

    final parts = code.split('_').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '쿠폰';

    // 끝이 금액처럼 보이는 숫자 토큰이면 제거 (STARBUCKS_5000)
    while (parts.length > 1 && int.tryParse(parts.last) != null) {
      parts.removeLast();
    }

    for (final p in parts) {
      if (int.tryParse(p) != null) continue;
      final key = p.toUpperCase();
      final brand = _brandByToken[key];
      if (brand != null) return '$brand 쿠폰';
    }

    // 복합: KYOCHON_CHICKEN → 첫 토큰만 매칭 시도 후 나머지는 무시
    final first = parts.firstWhere((p) => int.tryParse(p) == null, orElse: () => parts.first);
    final k = first.toUpperCase();
    final b = _brandByToken[k];
    if (b != null) return '$b 쿠폰';

    // 폴백: 영문 토큰을 단어처럼 보이게 + 쿠폰
    final words = parts.where((p) => int.tryParse(p) == null).map(_prettyWord).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '쿠폰';
    return '${words.join(' ')} 쿠폰';
  }

  static String _prettyWord(String token) {
    if (token.isEmpty) return '';
    final lower = token.toLowerCase();
    return lower[0].toUpperCase() + (lower.length > 1 ? lower.substring(1) : '');
  }
}
