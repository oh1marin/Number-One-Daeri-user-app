# Flutter 앱 연동 가이드

> BACKEND_SPEC.md 기준 — 일등대리 앱 API

---

## 1. Base URL

| 환경 | Base URL |
|------|----------|
| Android 에뮬레이터 | `http://10.0.2.2:5174/api/v1` |
| iOS 시뮬레이터 | `http://localhost:5174/api/v1` |
| 실서버 | `https://api.your-domain.com/api/v1` |

---

## 2. 인증 (Auth)

### 2.1 회원가입
```
POST /auth/register
Body: { "email", "password", "name", "phone?" }
Response: { "user": { id, email, name, phone, mileage }, "accessToken", "refreshToken" }
```

### 2.2 로그인
```
POST /auth/login
Body: { "email", "password" }
Response: { "user": { id, email, name, phone, mileage }, "accessToken", "refreshToken" }
```

### 2.3 토큰 갱신
```
POST /auth/refresh
Body: { "refreshToken" }
Response: { "accessToken" }
```

### 2.4 내 정보
```
GET /auth/me
Header: Authorization: Bearer <token>
Response: { id, email, name, phone, mileage }
```

---

## 3. 공지사항

```
GET /notices?page=1&limit=10
Response: { "items": [{ id, title, content, createdAt }], "total" }

GET /notices/latest
Response: { id, title, content, createdAt } | null  (홈용 최신 1건)

GET /notices/:id
```

---

## 4. 마일리지

```
GET /users/me/mileage
Response: { "balance": 10000, "withdrawable": 10000 }
```
- **가입 시**: 10,000원 적립 (앱 다운로드)
- **카드 결제 시**: 이용금액의 5% 적립
- withdrawable = balance (전액 출금 가능)
- 출금: POST /withdrawals

```
GET /mileage/history?page=1&limit=20
Response: { "items": [{ id, type, amount, balance, description, createdAt }], "total" }
```
- type: "earn" | "use" | "withdraw"

---

## 5. 대리운전 콜

```
POST /rides/call
Body: {
  "latitude": number,
  "longitude": number,
  "address": "경기도 평택시 용이동 737",
  "addressDetail": "상세주소",
  "phone": "16680001"
}
Response: { "rideId", "status", "estimatedTime?" }
```

### 역지오코딩 (선택)
```
GET /geocode/reverse?lat=...&lng=...
Response: { "address", "addressDetail", "region" }
```

---

## 6. 이용내역 (운행)

```
GET /rides/my?page=1&limit=20&status=completed
Response: {
  "items": [{ id, date, time, pickup, dropoff, fare, discount, extra, total, status, driverName }],
  "total"
}

GET /rides/:id
```

---

## 7. 출금신청

```
POST /withdrawals
Body: {
  "amount": 20000,       // 20,000원 이상, 10,000원 단위
  "bankCode": "국민",
  "accountNumber": "123-456-789",
  "accountHolder": "홍길동"
}
Response: { "id", "status", "requestedAt" }
```

```
GET /banks
Response: [{ "code", "name" }]
```

---

## 8. 카드관리

```
POST /cards
Body: { "cardToken", "cardName", "expiryDate", "option" }

GET /cards
Response: [{ "id", "cardName", "last4Digits", "expiryDate" }]

DELETE /cards/:id
```

---

## 9. 추천인 (친구 추천 이벤트)

```
POST /referrals/register
Body: { "referrerPhone": "01012345678" }
Response: { "success", "reward": 10000 }
```

**추천인 혜택**: 친구 추천 시 2,000원 + 친구 첫 이용 시 3,000원 추가 + 친구 이용금액 2% 적립  
**친구 혜택**: 추천받은 친구 10,000원 적립  
**추가 보너스**: 2명 추천 시 10,000원, 5명 추천 시 30,000원

```
GET /referrals/my
Response: { "referrer": { phone, name } | null, "totalReward", "referredCount" }
```

---

## 10. 1:1 문의

```
POST /inquiries
Body: { "content": "문의 내용" }
Response: { "id", "status", "createdAt" }

GET /inquiries
Response: { "items": [{ id, content, reply, status, createdAt }] }

GET /inquiries/:id/messages
POST /inquiries/:id/messages
Body: { "content": "추가 문의" }
```

---

## 11. 불편신고

```
POST /complaints
Body: { "type", "content", "rideId?", "attachments?" }
Response: { "id", "status" }
```

---

## 12. 이벤트

```
GET /events
Response: [{ "id", "title", "imageUrl", "startAt", "endAt", "url" }]
```

---

## 13. 자주하는질문

```
GET /faqs
Response: { "items": [{ id, question, answer }] }
```

---

## 14. 쿠폰등록

```
POST /coupons/register
Body: { "code": "COUPON123" }
Response: { "amount", "message" }
```

---

## 15. 알림설정

```
GET /users/me/settings
Response: { pushEnabled, ... }

PATCH /users/me/settings
Body: { "pushEnabled": true }
Response: { pushEnabled, ... }
```

---

## 16. 계정삭제

```
DELETE /users/me
Body: { "password": "현재비밀번호" }
Response: { "message": "계정이 삭제되었습니다." }
```

---

## 17. 공통

### 응답 포맷
```json
{ "success": true, "data": { ... } }
{ "success": false, "error": "에러 메시지" }
```

### 인증 헤더
```
Authorization: Bearer <accessToken>
```

### 401 처리
- 401 수신 시 `POST /auth/refresh` 로 토큰 갱신 후 재시도
- 갱신 실패 시 로그인 화면 유도

---

## 18. 우선순위 (구현 순서)

| 순위 | 기능 | 엔드포인트 |
|------|------|-----------|
| 1 | 인증 | /auth/* |
| 2 | 내 정보 + 마일리지 잔액 | /auth/me, /users/me/mileage |
| 3 | 대리운전 콜 | POST /rides/call |
| 4 | 이용내역 | GET /rides/my |
| 5 | 마일리지 내역 | GET /mileage/history |
| 6 | 공지사항 | GET /notices |
| 7 | 추천인 | /referrals/* |
| 8 | 출금신청 | POST /withdrawals, GET /banks |
| 9 | 1:1 문의 | /inquiries/* |
| 10 | 카드등록 | /cards/* |
| 11 | 불편신고, 이벤트 | /complaints, /events |
