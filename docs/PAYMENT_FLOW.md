# 결제 플로우 (Flutter ↔ 백엔드)

## 1. 콜 생성 시 paymentMethod

`POST /rides/call` Body에 포함:

| 값 | 설명 |
|----|------|
| `cash` | 현금 |
| `mileage` | 마일리지 |
| `card` | 카드 (운행 완료 후 PG 결제) |
| `kakaopay` | 카카오페이 (운행 완료 후 PG 결제) |

---

## 2. 카드 결제 플로우

### 2-1. 등록 카드로 결제 (저장된 카드)

1. 사용자가 **등록 카드** 선택 → `GET /cards`로 카드 목록 조회
2. 카드 선택 후 콜 생성: `POST /rides/call` with `paymentMethod: 'card'`, `cardId`
3. **즉시 결제**: `POST /payments/charge-with-card` 호출

```
POST /payments/charge-with-card
Body: { "rideId", "amount", "cardId" }
```

- 백엔드에서 cardId로 빌링키 조회 후 PortOne API로 결제 청구
- `POST /cards` 시 transactionId로 빌링키 발급 후 저장 필요

### 2-2. PG 결제창 (카카오페이/토스)

1. 콜 생성 시 `paymentMethod: 'kakaopay'` 또는 `'card'`(토스) 전달
2. Flutter에서 PG 결제창 진행
3. 결제 성공 시 `POST /payments` 호출:

```json
{
  "rideId": "콜ID",
  "amount": 25000,
  "cardId": "카드ID",
  "pgTid": "PG거래ID",
  "pgProvider": "portone"
}
```

- 백엔드는 결제 결과만 저장

---

## 3. 마일리지 결제

- 콜 시 `paymentMethod: 'mileage'` 전달
- `estimatedFare` 이하 잔액 필요 (콜 생성 시 백엔드 검증)
- 잔액 부족 시 `INSUFFICIENT_MILEAGE` 에러
- 실제 차감은 **기사가 완료 처리할 때** 백엔드에서 처리

---

## 4. 마일리지 적립 (백엔드 자동)

적립은 **드라이버 앱**에서 `POST /driver/rides/:id/complete`가 호출될 때만 처리됩니다.  
(이 저장소의 **유저용 Flutter 앱 ride_fe**는 완료 API를 호출하지 않습니다.)

### 4-1. 이용금액 산정 (`resolveCompletionFareAmount`)

적립 계산에 쓰는 “이용금액”은 아래 순으로 결정됩니다.

1. 완료 요청 바디의 `total` 또는 `fare`
2. 없으면 DB에 저장된 `total` / `fare`
3. 그것도 없으면 **`estimatedFare`** 폴백

과거에 적립이 **0원으로 스킵**되던 대표 원인은 다음과 같습니다.

- 완료 시 `total`/`fare`를 안 넘기고, DB에도 `total`이 0 → 이용금액이 0으로 잡힘
- 앱 콜은 `estimatedFare`만 있고 최종 요금이 아직 안 찍힌 경우 → 예전에는 `estimatedFare`를 안 써서 적립 없음 → **현재는 3번 폴백으로 반영**

### 4-2. 적립률·중복 방지

- 이용자 적립: **이용금액 × `AccumulationSettings.rideEarnRate`** (설정 없으면 기본 **0.1 = 10%**). 관리자에서 비율 변경 가능.
- 마일리지 결제 콜: 요금 차감 처리(이미 차감된 콜은 `mileageHistory`로 **중복 차감 방지**).
- 적립·추천인 적립: `description`에 **`· ride:<콜ID>`** 등을 넣어 **같은 콜에 두 번 적립**되지 않게 처리.
- 추천인: 기존과 동일(피추천인 이용 **5%** + 첫 이용 보너스 등).

### 4-3. 유저 앱에서 할 일

- 적립 트리거는 **기사 완료 API**뿐이므로, ride_fe는 완료 시 금액을 보낼 수 없습니다.
- 운행 종료 후 사용자는 **마일리지 화면 새로고침**으로 `GET /mileage/history`, `GET /users/me/mileage`로 반영 여부를 확인하면 됩니다.
- **쿠폰·상품권 등은 마일리지와 분리하는 것이 원칙**입니다. ride_fe 마일리지 화면의 **이용 내역 목록**에서는 쿠폰으로 보이는 행을 표시하지 않습니다. 다만 **보유 마일리지 숫자**는 서버 `GET /users/me/mileage` 값 그대로이므로, 쿠폰을 잔액·적립에 섞지 않으려면 **백엔드에서 적립/잔액 산정 시 쿠폰을 제외**해야 합니다.

### 4-4. 드라이버 앱·기타 경로

- 완료 요청 시 가능하면 **`total`(또는 `fare`)에 실제 청구 금액**을 넣는 것이 가장 정확합니다. 안 넣어도 이제는 `estimatedFare` 폴백이 있습니다.
- 관리자 등 **다른 API로 콜만 `completed`로 바꾸는 경로**가 있다면, 그 시점에도 동일한 마일리지 완료 서비스를 호출해야 적립이 들어갑니다. (현재 백엔드는 완료 처리가 드라이버 complete 한 곳이라고 가정한 설명이 있음.)

---

## 5. Flutter 구현 상태 (ride_fe — 유저 앱)

| 항목 | 상태 |
|------|------|
| paymentMethod 콜 전달 | ✅ |
| 마일리지 잔액 검증 (호출 전) | ✅ |
| INSUFFICIENT_MILEAGE 에러 처리 | ✅ |
| 마일리지 화면 API 연동 | ✅ GET /users/me/mileage, GET /mileage/history |
| 등록 카드로 결제 (저장된 카드) | ✅ charge-with-card 호출 |
| 카드 PG 결제창 (카카오페이/토스) | ✅ PaymentScreen |
| 카드 등록 (PortOne 100원 인증) | ✅ |
| 드라이버 완료 API / 적립 트리거 | 해당 없음 (드라이버 앱·백엔드) |
