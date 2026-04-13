# 일등대리 - 백엔드 기능 구현 요구사항

> Flutter 앱과 연동하기 위해 백엔드에서 구현해야 할 API 및 기능 목록

---

## 1. 앱 개요

**서비스명**: 일등대리 (Number One Daeri)  
**대표번호**: 1668-0001  
**앱 유형**: 대리운전 호출/관리 사용자 앱

---

## 2. 인증 (Auth)

> **사용자 앱은 전화번호 인증 기반** (이메일/비밀번호 아님)

### 2.1 전화번호 인증 — SMS OTP 발송
```
POST /auth/phone/send
Body: { "phone": "01012345678" }
Response: { "success": true }
```
- 전화번호 형식: 숫자만, 10~11자리
- SMS 인증번호(6자리) 발송
- 일일 발송 횟수 제한 권장

### 2.2 전화번호 인증 — OTP 검증 + 로그인/회원가입
```
POST /auth/phone/verify
Body: { "phone": "01012345678", "code": "123456" }
Response: {
  "success": true,
  "user": { "id", "phone", "name?", "mileage?" },
  "accessToken": "...",
  "refreshToken": "..."
}
```
- OTP 일치 시: 기존 사용자면 로그인, 없으면 자동 가입 후 로그인
- 가입 시 10,000원 마일리지 지급

### 2.3 (기존) 이메일 회원가입 — 관리자용
```
POST /auth/register
Body: { "email", "password", "name", "phone?" }
Response: { "user": {...}, "accessToken", "refreshToken" }
```

### 2.4 (기존) 이메일 로그인 — 관리자용
```
POST /auth/login
Body: { "email", "password" }
Response: { "user": {...}, "accessToken", "refreshToken" }
```

### 2.5 토큰 갱신
```
POST /auth/refresh
Body: { "refreshToken" }
Response: { "accessToken" }
```

### 2.6 내 정보
```
GET /auth/me
Header: Authorization: Bearer <token>
Response: { "id", "email", "name", "phone", "mileage?" }
```

---

## 3. 홈 화면

### 3.1 공지사항
```
GET /notices
Query: ?page=1&limit=10
Response: { "items": [{ "id", "title", "content", "createdAt" }], "total" }
```

### 3.2 마일리지 잔액
```
GET /users/me/mileage
Response: { "balance": 10000, "withdrawable": 10000 }
```
- 가입 시 10,000원 지급, 카드 결제 시 이용금액의 5% 적립
- withdrawable = balance (잔액 전액 출금 가능)

---

## 4. 대리운전 호출

### 4.1 콜 생성 (24시간 앱 접수 / 전화 접수)
```
POST /rides/call
Header: Authorization: Bearer <token>
Body: {
  "latitude": number,
  "longitude": number,
  "address": "경기도 평택시 용이동 737",
  "addressDetail": "상세주소",
  "phone": "16680001",
  "transmission": "auto" | "stick",      // 선택. 오토/스틱
  "serviceType": "daeri" | "taksong",    // 선택. 대리운전/탁송
  "quickBoard": "possible" | "impossible", // 선택. 퀵보드 가능/불가
  "vehicleType": "sedan" | "9seater" | "12seater" | "cargo1t"  // 선택. 승용차/9인승/12인승/화물1톤
}
Response: { "rideId", "status", "estimatedTime?" }
```
- 앱에서 대리호출 옵션 화면에서 선택 후 전달. 관리자에서 조회/배차 시 참고.

### 4.2 현재 위치 기반 주소 조회 (선택)
```
GET /geocode/reverse?lat=...&lng=...
Response: { "address", "addressDetail", "region" }
```

---

## 5. 이용내역 (운행내역)

### 5.1 내 운행 목록
```
GET /rides/my
Header: Authorization: Bearer <token>
Query: ?page=1&limit=20&status=completed
Response: {
  "items": [{
    "id", "date", "time",
    "pickup", "dropoff",
    "fare", "discount", "extra", "total",
    "status", "driverName?"
  }],
  "total"
}
```

### 5.2 운행 상세
```
GET /rides/:id
Response: { ...운행 상세 정보 }
```

---

## 6. 마일리지

- **가입 시**: 10,000원 지급
- **카드 결제 시**: 이용금액의 5% 적립
- **출금**: POST /withdrawals 사용 (사용자 간 이체 없음)
- **출금 가능액**: 잔액 전액 (withdrawable = balance)

### 6.1 잔액 및 출금가능액
```
GET /users/me/mileage
Response: { "balance": 10000, "withdrawable": 10000 }
```
- withdrawable = balance

### 6.2 적립/사용 내역
```
GET /mileage/history
Query: ?page=1&limit=20
Response: {
  "items": [{
    "id", "type": "earn"|"use"|"withdraw",
    "amount", "balance",
    "description", "createdAt"
  }],
  "total"
}
```

### 삭제된 API
- ~~POST /mileage/transfer~~ — 사용자 간 이체 기능 제거

---

## 7. 출금신청

- 사용자 간 이체 없음. 잔액 전액 출금 가능.

### 7.1 출금 요청
```
POST /withdrawals
Header: Authorization: Bearer <token>
Body: {
  "amount": 20000,        // 20,000원 이상, 10,000원 단위
  "bankCode": "국민",
  "accountNumber": "123-456-789",
  "accountHolder": "홍길동"
}
Response: { "id", "status", "requestedAt" }
```

### 7.2 은행 목록 (선택)
```
GET /banks
Response: [{ "code", "name" }]
```

---

## 8. 카드관리

### 8.1 카드 등록 (PG 연동 필요)
```
POST /cards
Body: {
  "cardToken": "...",     // PG사 토큰
  "cardName": "우리카드 끝자리 1234",
  "expiryDate": "MM/YY",
  "option": "영수증 발급 시 필요 정보"
}
```

### 8.2 등록된 카드 목록
```
GET /cards
Response: [{ "id", "cardName", "last4Digits", "expiryDate" }]
```

### 8.3 카드 삭제
```
DELETE /cards/:id
```

---

## 9. 추천인 (내추천인 등록)

### 리워드 구조
| 구분 | 혜택 |
|------|------|
| 모든 신규 가입 | 앱 가입 완료 시 10,000원 (기본 가입 보너스, 추천 아님) |
| 추천인 | 친구가 내 코드로 가입 시 2,000원 |
| 추천인 | 친구 첫 이용 시 3,000원 추가 |
| 추천인 | 친구가 이용금액 X 결제 시 X * 2% 적립 |
| 모든 사용자 | 카드 결제 시 이용금액의 5% 적립 |

### 2명/5명 보너스 (쿠폰, 마일리지 아님)
| 구분 | 지급 내용 |
|------|-----------|
| 2명 추천 | 스타벅스 쿠폰 2장 |
| 5명 추천 | 교촌치킨 세트 |

### 9.1 추천인 등록
```
POST /referrals/register
Body: { "referrerPhone": "01012345678" }
Response: { "success", "reward": 10000 }
```
- 가입자: 기본 10,000원 (모든 신규 동일) / 추천인: 2,000원

### 9.2 내 추천인 현황
```
GET /referrals/my
Response: {
  "referrer": { "phone", "name?" } | null,
  "totalReward", "referredCount",
  "tierCoupons": [{ "tier": 2|5, "rewardType": "coupon", "name": "...", "earnedAt" }]
}
```

---

## 10. 공지사항

```
GET /notices
GET /notices/:id
```
- 이미 3번에 포함

---

## 11. 1:1 문의 (Q&A)

### 11.1 문의 등록
```
POST /inquiries
Body: { "content": "문의 내용" }
Response: { "id", "status", "createdAt" }
```

### 11.2 문의 목록
```
GET /inquiries
Response: { "items": [{ "id", "content", "reply?", "status", "createdAt" }] }
```

### 11.3 문의 상세 (채팅형)
```
GET /inquiries/:id/messages
POST /inquiries/:id/messages
Body: { "content": "추가 문의" }
```

---

## 12. 불편신고

```
POST /complaints
Body: { "type", "content", "rideId?", "attachments?" }
Response: { "id", "status" }
```

---

## 13. 이벤트

```
GET /events
Response: [{ "id", "title", "imageUrl", "startAt", "endAt", "url?" }]
```

---

## 14. 공통 사항

### 14.1 응답 포맷
```json
// 성공
{ "success": true, "data": { ... } }

// 실패
{ "success": false, "error": "에러 메시지" }
```

### 14.2 인증 헤더
```
Authorization: Bearer <accessToken>
```

### 14.3 401 처리
- 401 수신 시 `POST /auth/refresh` 로 토큰 갱신 후 재시도
- 갱신 실패 시 로그인 화면 유도

---

## 15. 우선순위 (구현 순서 제안)

| 순위 | 기능 | 비고 |
|------|------|------|
| 1 | 인증 (회원가입/로그인/토큰) | 필수 |
| 2 | 내 정보 + 마일리지 잔액 | 홈 화면 |
| 3 | 대리운전 콜 생성 | 핵심 기능 |
| 4 | 이용내역 (운행 목록) | |
| 5 | 마일리지 내역 | |
| 6 | 공지사항 | |
| 7 | 추천인 등록 | |
| 8 | 출금신청 | |
| 9 | 1:1 문의 | |
| 10 | 카드등록 | PG 연동 필요 |
| 11 | 불편신고, 이벤트 | |

---

## 16. 환경별 Base URL

| 환경 | URL |
|------|-----|
| 로컬/개발 | `http://10.0.2.2:5174/api/v1` (Android 에뮬) |
| 실서버 | `https://api.your-domain.com/api/v1` |
