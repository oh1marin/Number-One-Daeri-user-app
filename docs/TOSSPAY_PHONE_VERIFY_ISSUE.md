# 토스페이 전화번호 인증 — 인증 코드 미수신 이슈

## 증상

- 토스페이 결제 시 전화번호 입력 후 **인증 코드(SMS)가 도착하지 않음**

## 원인 가능성

### 1. 테스트 환경에서 실제 SMS 미발송

- PortOne **테스트 채널** 또는 토스페이먼츠 **테스트 모드**에서는 실제 SMS를 보내지 않는 경우가 많음
- 테스트용 전화번호·고정 인증코드를 사용하는 경우가 있음

### 2. 카드 vs 토스 결제 플로우 차이

| 결제 수단 | 사용 위젯 | `isTestChannel` 전달 |
|-----------|-----------|----------------------|
| 카드 | `PortoneBillingKeyWebView` | ✅ `useTestChannel` 사용 |
| 토스 | `PortonePayment` (portone_flutter_v2) | ❌ `PaymentRequest`에 `isTestChannel` 없음 |

- 토스 결제는 `portone_flutter_v2`의 `PortonePayment`를 사용
- `PaymentRequest`에 `isTestChannel` 파라미터가 없음 → 테스트 모드 여부는 **채널 설정**으로만 결정됨

### 3. PortOne 채널 설정

- PortOne 콘솔에서 해당 채널이 **테스트**인지 **운영**인지 확인
- 테스트 채널: 실제 결제·SMS 없이 시뮬레이션만 가능할 수 있음

## 대응 방법

### A. PortOne 콘솔 설정 확인

1. [PortOne 콘솔](https://admin.portone.io) 접속
2. 해당 Store → **채널** 메뉴에서 `PORTONE_CHANNEL_KEY`에 해당하는 채널 확인
3. 채널이 **테스트**인지 **운영**인지 확인
4. 테스트 채널 사용 시: 토스페이먼츠 개발자 문서에서 **테스트 전화번호·고정 인증코드** 존재 여부 확인

### B. 토스페이먼츠 개발자 센터 확인

- [토스페이먼츠 개발자센터](https://developers.tosspayments.com/) 또는 PortOne 연동 문서에서
- 테스트 환경에서 사용할 **테스트 전화번호**
- **고정 인증코드**(예: `123456`) 여부 확인

### C. 운영 채널로 전환 (실제 결제 테스트용)

- 운영 채널 + 토스페이먼츠 운영 연동이 되어 있으면 실제 SMS 발송 가능
- PG 계약·인증서 등 사전 연동이 완료되어 있어야 함

### D. 코드 레벨 (현재 한계)

- `portone_flutter_v2`의 `PaymentRequest`에 `isTestChannel`이 없음
- 토스 결제를 테스트 채널로 고정하려면:
  - 별도 **테스트용 채널**을 만들고, 그 채널의 `channelKey`를 토스 결제에 사용
  - 또는 `portone_flutter_v2`에 `isTestChannel`/`bypass` 지원 여부 확인 후, 있으면 적용

## 다음 단계

1. **PortOne 고객센터 / 개발자 문서**에 문의
   - 테스트 채널에서 토스페이 전화번호 인증 시 SMS 발송 여부
   - 테스트용 전화번호·인증코드 제공 여부
2. **토스페이먼츠 개발자 문서**에서 테스트 결제·본인인증 가이드 확인
3. 운영 환경에서 실제 결제 테스트 시에는 운영 채널 사용

## 관련 파일

- `lib/screens/payment/payment_screen.dart` — 토스 결제 시 `PortonePayment` 사용
- `lib/config/portone_config.dart` — `portoneChannelKey`, `portoneUseTestChannel`
- `assets/env_defaults.env` — `PORTONE_CHANNEL_KEY`, `PORTONE_USE_TEST_CHANNEL`
