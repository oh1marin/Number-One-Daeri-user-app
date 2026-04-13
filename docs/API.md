# API 연동

## POST /payments

결제 완료 시 Flutter에서 호출.

### 요청 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| rideId | string | O | 결제 대상 콜 ID |
| amount | number | O | 결제 금액 (원) |
| pgTid | string | O | PG 거래 ID (PortOne transactionId) |
| pgProvider | string | O | 'portone' \| 'kakaopay' \| 'tosspay' |
| **billingKey** | string | - | 빌링키. pgProvider='portone'이고 billingKey+cardName 있으면 동일 카드 없을 때 자동 저장 |
| **cardName** | string | - | 마스킹된 카드명 (예: 신한카드 ****1234) |
| cardId | string | - | 기존 등록 카드 ID |
| receiptUrl | string | - | 영수증 URL |
| rawResponse | object | - | PortOne 원본 응답 |

### 응답

- `data.cardSaved === true`: 이번 결제로 카드가 새로 저장된 경우 → "카드가 저장되었습니다. 다음 결제부터 사용 가능합니다" 안내
