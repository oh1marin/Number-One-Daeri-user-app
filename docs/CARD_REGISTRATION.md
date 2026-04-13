# 카드 등록 가이드

## 흐름 요약

1. **PG 연동** → 사용자가 카드정보 입력 (PG 결제창)
2. **PG가 cardToken 발급** → 카드번호는 서버에 저장 안 함 (PCI-DSS)
3. **POST /cards** → cardToken + 카드명 + 유효기간 전달
4. **백엔드** → PG/카드사에 카드 등록 요청 후 id 반환

---

## PG 연동 방법 (PortOne 기준)

### 1단계: PortOne 가입 및 키 발급

1. [PortOne 콘솔](https://admin.portone.io) 가입
2. **Store** 생성 → **storeId** 복사
3. **Channel** 생성 (카드 결제) → **channelKey** 복사
4. 테스트 모드로 PG(NHN KCP, 토스페이먼츠 등) 연동

### 2단계: Flutter 패키지 추가

```yaml
# pubspec.yaml
dependencies:
  portone_flutter_v2: ^1.3.0
```

```bash
flutter pub get
```

### 3단계: 환경 설정

`lib/config/portone_config.dart` - 테스트 키 입력됨

### 4단계: 카드 등록 흐름 (2가지 방식)

#### 방식 A: 100원 인증 결제

- 100원 결제로 카드 유효성 검증
- 결제 성공 시 `paymentId` 또는 PG 응답의 `receipt`를 백엔드에 전달
- 백엔드가 PG API로 빌링키 발급

#### 방식 B: 카드 토큰화 (Card Tokenisation)

- PortOne 카드 토큰화 API 사용
- 카드 입력 폼 → 토큰 발급 → `POST /cards`에 `cardToken` 전달
- [PortOne 카드 토큰화](https://dev-docs.portone.cloud/th/docs/integration_guide/card_tokenisation_api/) 참고

### 5단계: 코드 예시 (방식 A - 100원 인증)

```dart
import 'package:portone_flutter_v2/portone_flutter_v2.dart';

// 카드 등록용 100원 인증 결제
final request = PaymentRequest(
  storeId: portoneStoreId,
  paymentId: 'card-reg-${DateTime.now().millisecondsSinceEpoch}',
  orderName: '카드 등록 인증',
  totalAmount: 100,
  currency: PaymentCurrency.KRW,
  channelKey: portoneChannelKey,
  payMethod: PaymentPayMethod.card,
  appScheme: portoneAppScheme,
  pg: PGCompany.tosspayments,  // 또는 NHN KCP, 나이스 등
);

// PortonePayment 위젯으로 결제창 표시
// callback에서 성공 시 receipt/cardInfo를 백엔드에 전달
```

### 6단계: Android/iOS 설정

**Android** `AndroidManifest.xml`:
- `INTERNET` 권한
- `<queries>` (결제앱 패키지) - portone_flutter_v2 문서 참고

**iOS** `Info.plist`:
- `LSApplicationQueriesSchemes` (결제앱 URL schemes)
- `CFBundleURLTypes` - `portoneAppScheme` 등록

---

## 백엔드 협의 사항

| 항목 | 설명 |
|------|------|
| cardToken 형식 | PortOne/토스 등 PG별 토큰 형식이 다름 |
| 100원 인증 | `paymentId`/`tid`만 받고 백엔드에서 PG API로 빌링키 발급하는 방식 가능 |
| option 필드 | 영수증용 사업자번호 등 - PG/백엔드 요구사항 확인 |

---

## Flutter 구현 상태

| 항목 | 상태 |
|------|------|
| GET /cards, DELETE /cards | ✅ |
| CardScreen 목록/삭제 | ✅ |
| POST /cards (API) | ✅ |
| PortOne SDK 연동 | ⏳ storeId, channelKey 설정 후 구현 |

---

## 참고

- 카드번호는 **절대** 앱/백엔드에 저장하지 않음
- cardToken은 PG가 일회성으로 발급 → 백엔드가 PG API로 빌링키 등록
- PCI-DSS 준수를 위해 PG 연동 필수
