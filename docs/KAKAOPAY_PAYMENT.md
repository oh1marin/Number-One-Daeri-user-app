# 앱결제 연동 (카카오페이 / 토스)

## 1. 구현 상태

| 항목 | 상태 |
|------|------|
| 결제 수단 선택 (대리호출 시) | ✅ 현금, 마일, **앱결제** 칩 |
| 앱결제 선택 시 세부 수단 | ✅ 카카오페이 / 토스 bottom sheet |
| paymentMethod 백엔드 전달 | ✅ `kakaopay` / `tosspay` (토스) |
| PaymentScreen | ✅ 카카오페이 / 토스 지원 |

---

## 2. 사용 방법

### 호출 플로우

1. 목적지 선택 → **앱결제** 칩 선택 → 대리호출 → 옵션 확인
2. 호출 확인 다이얼로그에서 호출 탭
3. **카카오페이 / 토스** 선택 bottom sheet 표시
4. 선택 후 결제창 진행 → 결제 완료 시 POST /payments

### 라우트로 결제 화면 직접 호출

```dart
// 카카오페이
Navigator.pushNamed(context, '/payment', arguments: {
  'rideId': rideId, 'amount': 25000, 'orderName': '대리운전 이용료',
  'kakaopay': true,
});

// 토스
Navigator.pushNamed(context, '/payment', arguments: {
  'rideId': rideId, 'amount': 25000, 'orderName': '대리운전 이용료',
  'toss': true,
});
```

### 결제 성공 후 POST /payments

```dart
final result = await Navigator.pushNamed(context, '/payment', arguments: {...});
if (result is Map && result['success'] == true) {
  await PaymentsApi.post(
    amount: amount,
    rideId: rideId,
    pgTid: result['transactionId'],
    pgProvider: isKakaopay ? 'kakaopay' : 'tosspay',
  );
}
```

---

## 3. PortOne 카카오페이 채널

- 카카오페이는 **PGCompany.kakaopay** 사용 (payMethod: easyPay)
- PortOne 콘솔에서 **카카오페이 채널** 연동 필요
- 기존 카드 채널과 별도, 또는 토스페이먼츠 등에서 카카오페이를 easyPay로 지원하는 PG 사용 가능
- 채널 설정 후 `portone_config.dart`의 `channelKey`를 카카오페이용으로 변경하거나, 카드/카카오페이 각각 다른 channelKey 사용 가능

---

## 4. 결제 수단별 PG

| 결제 수단 | PortOne payMethod | PGCompany | pgProvider (POST /payments) |
|----------|-------------------|-----------|----------------------------|
| 카카오페이 | easyPay | kakaopay | kakaopay |
| 토스(스페이) | card | tosspayments | tosspay |
