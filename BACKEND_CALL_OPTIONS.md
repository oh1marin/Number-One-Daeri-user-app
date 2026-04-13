# 대리호출 화면 — 백엔드 수정요소

> 앱의 대리호출 화면(프리미엄/빠른/일반 호출, 현금/카드/마일 결제)과 연동하기 위한 백엔드 API 확장 요구사항

---

## 1. 개요

현재 앱에서는 다음 옵션을 사용자가 선택할 수 있으며, 백엔드에서 이를 반영해 처리해야 합니다.

| 구분 | 옵션 | 비고 |
|------|------|------|
| **호출 유형** | 프리미엄 호출 | 고급요금, 초고속배차 |
| | 빠른 호출 | 합리적요금, 일반배차 |
| | 일반 호출 | 저렴한요금, 여유있는배차 |
| **결제 수단** | 현금 | 도착 후 현금 결제 |
| | 마일 | 마일리지 잔액으로 결제 |
| | 카드 | 등록된 카드로 결제 |

---

## 2. API 수정 요구사항

### 2.1 콜 생성 API 확장 (POST /rides/call)

**기존 Body:**
```json
{
  "latitude": number,
  "longitude": number,
  "address": "경기도 평택시 용이동 737",
  "addressDetail": "상세주소",
  "phone": "16680001"
}
```

**확장 Body (추가 필드):**
```json
{
  "latitude": number,
  "longitude": number,
  "address": "경기도 평택시 용이동 737",
  "addressDetail": "상세주소",
  "phone": "16680001",

  "destinationLatitude": number,
  "destinationLongitude": number,
  "destinationAddress": "부산광역시 해운대구 우동",

  "fareType": "premium" | "fast" | "normal",
  "paymentMethod": "cash" | "mileage" | "card",

  "estimatedDistanceKm": number,
  "estimatedFare": number
}
```

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| destinationLatitude | number | N | 도착지 위도 |
| destinationLongitude | number | N | 도착지 경도 |
| destinationAddress | string | N | 도착지 주소/장소명 |
| fareType | string | Y | `premium`, `fast`, `normal` 중 하나 |
| paymentMethod | string | Y | `cash`, `mileage`, `card` 중 하나 |
| estimatedDistanceKm | number | N | 예상 거리(km) |
| estimatedFare | number | N | 예상 요금(원) |

---

### 2.2 요금 산정 API (신규 권장)

**목적:** 출발지·도착지 좌표를 기반으로 호출 유형별 예상 요금 반환

```
POST /rides/estimate
Header: Authorization: Bearer <token>
Body: {
  "originLatitude": number,
  "originLongitude": number,
  "destinationLatitude": number,
  "destinationLongitude": number
}
Response: {
  "distanceKm": number,
  "fares": {
    "premium": number,
    "fast": number,
    "normal": number
  }
}
```

- `distanceKm`: 예상 주행 거리(km)
- `fares.premium`: 프리미엄 호출 예상 요금(원)
- `fares.fast`: 빠른 호출 예상 요금(원)
- `fares.normal`: 일반 호출 예상 요금(원)

**비고:** 없을 경우 앱에서는 직선 거리 기반 임시 산정식을 사용합니다.

---

### 2.3 결제 수단별 처리

| paymentMethod | 백엔드 처리 |
|---------------|-------------|
| cash | 도착 후 현금 결제. `paymentMethod: "cash"` 저장 |
| mileage | 마일리지 잔액 차감. 잔액 부족 시 호출 거부 또는 별도 에러 |
| card | 등록 카드로 결제. 카드 미등록 시 호출 거부 또는 별도 에러 |

**마일리지 결제 시:**

- `GET /users/me/mileage` 로 잔액 확인
- 호출 시 `estimatedFare` 이상의 잔액 필요
- 결제 완료 시 마일리지 차감 처리

**카드 결제 시:**

- `GET /cards` 로 등록 카드 존재 여부 확인
- 등록된 카드가 없으면 `paymentMethod: "card"` 선택 불가 또는 경고

---

### 2.4 카드 등록 API (기존)

```
POST /cards
Body: {
  "cardToken": "...",
  "cardName": "우리카드 끝자리 1234",
  "expiryDate": "MM/YY",
  "option": "..."
}

GET /cards
Response: [{ "id", "cardName", "last4Digits", "expiryDate" }]

DELETE /cards/:id
```

- 카드 결제 선택 시, 등록된 카드가 없으면 카드 등록 플로우로 유도

---

## 3. 앱 → 백엔드 연동 요약

| 앱 UI | 전달 값 |
|-------|---------|
| 프리미엄 호출 | `fareType: "premium"` |
| 빠른 호출 | `fareType: "fast"` |
| 일반 호출 | `fareType: "normal"` |
| 현금 | `paymentMethod: "cash"` |
| 마일 | `paymentMethod: "mileage"` |
| 카드 | `paymentMethod: "card"` |

---

## 4. 에러 처리

| 상황 | HTTP | 응답 예시 |
|------|------|-----------|
| 마일리지 잔액 부족 | 400 | `{ "error": "INSUFFICIENT_MILEAGE", "message": "마일리지 잔액이 부족합니다." }` |
| 카드 미등록 | 400 | `{ "error": "NO_CARD_REGISTERED", "message": "결제용 카드를 먼저 등록해 주세요." }` |
| 해당 호출 유형 비활성 | 400 | `{ "error": "FARE_TYPE_UNAVAILABLE", "message": "선택한 호출 유형은 현재 이용할 수 없습니다." }` |

---

## 5. 구현 우선순위 제안

1. **1단계:** `POST /rides/call` 에 `fareType`, `paymentMethod` 필드 추가
2. **2단계:** 도착지 필드 추가 (`destinationLatitude`, `destinationLongitude`, `destinationAddress`)
3. **3단계:** `POST /rides/estimate` 요금 산정 API 구현 (선택)
4. **4단계:** `paymentMethod: "mileage"` 시 잔액 검증 및 차감 처리
5. **5단계:** `paymentMethod: "card"` 시 카드 등록 여부 검증
