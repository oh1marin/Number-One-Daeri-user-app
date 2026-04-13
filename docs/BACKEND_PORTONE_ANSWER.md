# 백엔드 PortOne 연동 — Flutter 쪽 답변

## 1. cardToken에 실제로 전달되는 값

| 항목 | 값 |
|------|-----|
| **필드명** | `transactionId` (PortOne V2의 `txId`) |
| **imp_uid와 관계** | imp_uid는 I'mport 레거시 API 용어. **PortOne V2에서는 transactionId 사용** |
| **출처** | PortOne 결제 성공 시 `PaymentResponse.transactionId` |

Flutter는 100원 인증 결제 성공 후 **transactionId**를 `cardToken`으로 `POST /cards`에 전달합니다.

```json
{
  "cardToken": "tx_xxxx...",  // ← transactionId 값
  "cardName": "우리카드 ****1234",
  "expiryDate": "MM/YY",
  "option": "..."
}
```

---

## 2. PortOne 키 (Flutter 기준)

| 변수 | Flutter 사용값 | 용도 |
|------|----------------|------|
| Store ID | `store-3a52a131-086e-4b5c-9002-1c5696cffee4` | 결제 요청 |
| Channel Key | `channel-key-727e7660-9ec6-4339-a642-1501d9492d34` | 결제 채널 |
| Client Key | 테스트용 (앱에만 사용) | 클라이언트 SDK |
| Secret Key | 테스트용 | 서버 API용 (백엔드에서 사용) |

백엔드에서 PortOne 서버 API를 호출할 때는 **API Key, API Secret, Store ID**가 필요합니다.

---

## 3. 결제 방식

| 구분 | Flutter 구현 상태 | 비고 |
|------|-------------------|------|
| **A. 클라이언트 결제** | 지원 | 기사 완료 후 앱에서 PG 결제창 → `POST /payments`로 결과만 저장 |
| **B. 서버 결제** | 카드 등록만 | 카드 등록 시 `cardToken`(transactionId) 전달, 백엔드에서 빌링키 발급 후 저장 필요 |

현재 Flutter는 **A**를 전제로 동작합니다.  
- 콜 시 `paymentMethod: 'card'` 전달  
- 기사 운행 완료 후 앱에서 PortOne 결제창 → 결제 성공 시 `POST /payments` 호출  

**B**를 쓰려면 백엔드에서:
- `POST /cards` 수신 시 PortOne API로 transactionId → 빌링키 발급
- 기사 완료 시 저장된 빌링키로 자동 청구

---

## 4. 100원 인증 결제 환불

- **Flutter**: 환불 처리 없음
- **백엔드**: PortOne 취소 API로 환불 필요 (API Key/Secret 사용)
- **정책**: 언제, 어떻게 환불할지 정한 뒤 백엔드에서 처리

---

## 5. 카드 삭제 시 PortOne 연동

- Flutter: `DELETE /cards/:id` 호출만 수행
- PortOne 빌링키/구독 해제는 백엔드에서 처리 필요
- 필요 시 `DELETE /cards/:id` 처리 시 PortOne API로 해당 빌링키 비활성화 또는 삭제

---

## 6. PortOne API Key / Secret 발급

- **경로**: [PortOne 콘솔](https://admin.portone.io) → **설정(Settings)** → **API** 탭
- 또는: **우측 상단 계정** → **API 키** / **API Keys**
- **V2 API**용 Key, Secret 발급 후 `.env` 등에 설정

---

## 7. 요약

| 질문 | 답변 |
|------|------|
| cardToken에 들어가는 값 | **transactionId** (PortOne V2 txId) |
| Store ID | `store-3a52a131-086e-4b5c-9002-1c5696cffee4` |
| 서버 결제(B) 시 필요 | API Key, API Secret, Store ID |
| 100원 환불 | 백엔드에서 PortOne 취소 API 사용 |
| 카드 삭제 시 빌링키 | 백엔드에서 PortOne API로 해제 처리 |
