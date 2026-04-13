# 등록 카드 결제 — 백엔드 가이드

## 개요

- **100원 인증 없이 첫 결제 자동 저장**이 기본 동작입니다.
- 앱결제(카드/토스) 시 PortOne 빌링키 발급 + 초회 결제 플로우 사용 → `POST /payments`에 `billingKey`, `cardName` 전달 → 백엔드가 동일 카드 없으면 새로 저장 → `cardSaved: true` 응답
- 등록된 카드가 있으면 **등록 카드**로 결제 가능 (charge-with-card)

---

## A. 첫 결제 (카드 없음) 흐름

1. 사용자가 **앱결제** (카드/토스) 선택 → PortOne 결제창
2. PortOne: **빌링키 발급 + 초회 결제** 플로우 사용 (채널 설정 필요)
3. 결제 성공 시 Flutter가 응답에서 `billingKey`, `cardName` 추출
4. `POST /payments` 호출:

```json
{
  "rideId": "...",
  "amount": 25000,
  "pgTid": "transactionId",
  "pgProvider": "portone",
  "billingKey": "응답의 빌링키",
  "cardName": "신한카드 ****1234"
}
```

5. 백엔드: `pgProvider === 'portone'`이고 `billingKey`+`cardName` 있으면 → 동일 빌링키 카드 없으면 새 카드 저장, 결제 기록 연결
6. 응답에 `cardSaved: true` 포함 → Flutter에서 "카드가 저장되었습니다. 다음 결제부터 사용 가능합니다" 안내

---

## B. 등록 카드로 결제 흐름

1. 대리호출 화면에서 **등록 카드** 선택
2. `POST /rides/call` 호출: `{ ..., paymentMethod: 'card', cardId: '...' }`
3. `POST /payments/charge-with-card` 호출
4. 성공 시 "결제가 완료되었습니다" 표시

---

## API

### POST /api/v1/payments/charge-with-card

**요청**

```json
{
  "rideId": "콜 ID",
  "amount": 25000,
  "cardId": "등록 카드 ID"
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| rideId | string | O | 결제 대상 콜 ID |
| amount | number | O | 결제 금액 (원) |
| cardId | string | O | 등록된 카드 ID (GET /cards 목록에서 조회) |

**응답 (성공 201)**

```json
{
  "success": true,
  "data": {
    "id": "payment_id",
    "rideId": "...",
    "amount": 25000,
    "method": "card",
    "status": "completed",
    "pgTid": "PG거래ID",
    "card": { "id": "...", "cardName": "...", "last4Digits": "1234" },
    "message": "결제가 완료되었습니다."
  }
}
```

**에러**

- `503` — PORTONE_CHANNEL_KEY 미설정
- `400` — rideId/cardId 누락, amount 오류, 카드 없음, PortOne 결제 실패
- `404` — 콜을 찾을 수 없음

---

### POST /api/v1/payments — billingKey, cardName

앱결제(카드/토스) 완료 시 Flutter에서 호출. `billingKey`, `cardName`이 있으면 백엔드가 카드 자동 저장.

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| rideId | string | O | 결제 대상 콜 ID |
| amount | number | O | 결제 금액 |
| pgTid | string | O | transactionId (PortOne) |
| pgProvider | string | O | 'portone' \| 'kakaopay' |
| billingKey | string | - | 빌링키 (있으면 카드 저장) |
| cardName | string | - | 마스킹된 카드명 (예: 신한카드 ****1234) |

**응답**: `data.cardSaved === true` 이면 이번 결제로 카드가 새로 저장된 경우.

---

## 백엔드 환경 변수

`.env`에 다음이 필요합니다.

```
PORTONE_API_SECRET=...
PORTONE_STORE_ID=...
PORTONE_CHANNEL_KEY=channel-key-727e7660-9ec6-4339-a642-1501d9492d34
```

`PORTONE_CHANNEL_KEY`는 Flutter `portone_config.dart`의 channelKey와 동일해야 합니다.

---

## cardToken과 빌링키

- `cardToken`은 카드 등록 시 Flutter 100원 인증 결제 후 전달받는 값입니다.
- PortOne의 **인증 결제(빌링키 발급)** 플로우를 사용했다면, 이 값이 빌링키로 사용됩니다.
- 100원 인증만 하고 빌링키가 발급되지 않는 채널이라면, Flutter에서 **빌링키 발급** 전용 플로우를 사용하고 그 결과를 `cardToken`으로 전달해야 합니다.

**Flutter 동작 (카드 등록):**

- `requestIssueBillingKey` API 사용 (100원 인증 전용) → 응답의 `billingKey`를 `cardToken`으로 전달
- PortOne 콘솔에서 해당 채널에 빌링키 발급 기능이 활성화되어 있어야 함

**Flutter 동작 (앱 결제 + 카드 저장):**

- `requestIssueBillingKeyAndPay` API 사용 (빌링키 발급 + 첫 결제 동시) → 응답의 `billingKey`, `cardName`을 `POST /payments`에 전달

---

## POST /rides/call — cardId

등록 카드 선택 시 `cardId`를 함께 전달할 수 있습니다.

```json
{
  "address": "...",
  "paymentMethod": "card",
  "cardId": "등록_카드_ID",
  ...
}
```

`cardId`가 있으면 해당 카드가 본인 소유인지 검증합니다.
