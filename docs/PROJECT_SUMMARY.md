# 일등대리 앱 (number_one_daeri_user_app) — 프로젝트 요약

> 작성일: 2026-03-27  
> Flutter SDK: ^3.11.1 / Dart SDK: ^3.11.1  
> 앱 버전: 1.0.0+1

---

## 1. 프로젝트 개요

**일등대리**는 대리운전 호출 서비스 앱입니다.  
고객이 앱에서 직접 출발지·도착지를 지정해 대리기사를 24시간 호출할 수 있으며, 카드·마일리지·카카오페이·토스 등 다양한 결제 수단을 지원합니다.  
대표 전화번호는 **1668-0001**.

---

## 2. 폴더 구조

```
lib/
├── main.dart                   # 앱 진입점, 라우트 정의
├── api/                        # 백엔드 REST API 호출 레이어
├── config/                     # 환경 설정 (API URL, 카카오맵, 포트원)
├── models/                     # 데이터 모델
├── routes/                     # 관리자용 라우터 (AppRouter)
├── screens/                    # 화면 단위 UI
│   ├── onboarding/             # 권한, 약관, 전화인증, 추천인 등록
│   ├── home/                   # 홈, 메인 스캐폴드(드로어 포함)
│   ├── call/                   # 대리호출 (지도, 옵션, 목적지 검색)
│   ├── card/                   # 카드 등록·관리
│   ├── payment/                # PG 결제 (포트원 v2)
│   ├── ride_history/           # 이용내역
│   ├── mileage/                # 마일리지
│   ├── coupon/                 # 쿠폰
│   ├── referrer/               # 추천인 등록·현황
│   ├── notice/                 # 공지사항
│   ├── faq/                    # 자주하는 질문
│   ├── qa/                     # 고객센터 1:1 문의
│   ├── complaint/              # 불편신고
│   ├── event/                  # 이벤트
│   ├── withdrawal/             # 출금신청
│   ├── settings/               # 알림설정, 사고/과태료, 계정삭제, 요금설정
│   ├── auth/                   # 관리자 로그인/가입 (어드민용)
│   ├── dashboard/              # 어드민 대시보드
│   ├── customers/              # 어드민 고객 목록·상세
│   ├── drivers/                # 어드민 기사 목록·상세
│   ├── rides/                  # 어드민 운행 목록
│   ├── attendance/             # 어드민 출석
│   └── invoices/               # 어드민 청구서
├── services/                   # 비즈니스 로직·외부 SDK 래퍼
├── theme/                      # 앱 테마
├── utils/                      # 공통 유틸
└── widgets/                    # 공통 위젯
```

---

## 3. 라우팅

### 사용자 앱 라우트 (`main.dart`)

| 경로 | 화면 | 설명 |
|---|---|---|
| `/` | `_InitialRoute` | 온보딩 완료 여부에 따라 홈 또는 권한 화면으로 분기 |
| `/permission` | `PermissionScreen` | 위치·알림 권한 요청 |
| `/terms` | `TermsScreen` | 약관 동의 |
| `/phone-verify` | `PhoneVerifyScreen` | 휴대폰 인증 (SMS) |
| `/referrer` | `ReferrerScreen` | 추천인 등록 (온보딩 포함) |
| `/home` | `MainScaffold` | 메인 홈 화면 |
| `/call-map` | `CallMapScreen` | 대리호출 지도 화면 |
| `/card` | `CardScreen` | 카드 등록·관리 |
| `/payment` | `PaymentScreen` | PG 결제 |
| `/mileage` | `MileageScreen` | 마일리지 내역 |
| `/coupon` | `CouponScreen` | 쿠폰 등록 |
| `/referrer-status` | `ReferrerStatusScreen` | 추천인 현황 |
| `/ride-history` | `RideHistoryScreen` | 이용내역 |
| `/notice` | `NoticeScreen` | 공지사항 |
| `/faq` | `FaqScreen` | 자주하는 질문 |
| `/qa` | `QaScreen` | 고객센터 1:1 문의 |
| `/complaint` | `ComplaintScreen` | 불편신고 |
| `/event` | `EventScreen` | 이벤트 |
| `/withdrawal` | `WithdrawalScreen` | 출금신청 |
| `/notification-settings` | `NotificationSettingsScreen` | 알림 설정 |
| `/accident-penalty` | `AccidentPenaltyScreen` | 사고/과태료 |
| `/account-delete` | `AccountDeleteScreen` | 계정삭제 |

### 관리자 라우트 (`routes/app_router.dart`)

`/login`, `/register`, `/` (대시보드), `/customers`, `/customer-detail`, `/drivers`, `/driver-detail`, `/rides`, `/attendance`, `/invoices`, `/settings/fares`

---

## 4. API 레이어

### `ApiClient` (lib/api/api_client.dart)

- **Dio** 기반 HTTP 클라이언트 싱글톤
- `baseUrl`: Debug → `http://127.0.0.1:5174/api/v1/`, Release → 플레이스홀더 또는 `--dart-define=API_BASE_URL=...` (실제 운영 호스트는 빌드·팀 공유, `flutter-sideload-api-base-url.md`).
- **JWT Bearer 토큰** 자동 주입 (Interceptor)
- **401 자동 토큰 갱신**: 만료 시 refresh 시도 → 실패 시 `/phone-verify`로 이동
- **SSL 핀닝** (Release 모드, `.env`의 `API_CERT_PIN` 값으로 MITM 방지)

### API 파일 목록

| 파일 | 역할 |
|---|---|
| `auth_api.dart` | 인증 (로그인, refresh, me) |
| `rides_call_api.dart` | 대리호출 접수 |
| `rides_estimate_api.dart` | 요금 견적 |
| `rides_api.dart` | 운행 내역 |
| `cards_api.dart` | 카드 목록·삭제 |
| `card_payments_api.dart` | 카드 결제 |
| `mileage_api.dart` | 마일리지 조회 |
| `coupons_api.dart` | 쿠폰 |
| `referral_api.dart` | 추천인 |
| `notices_api.dart` | 공지사항 |
| `inquiry_api.dart` | 1:1 문의 |
| `complaints_api.dart` | 불편신고 |
| `events_api.dart` | 이벤트 |
| `customers_api.dart` | 어드민 고객 관리 |
| `drivers_api.dart` | 어드민 기사 관리 |
| `dashboard_api.dart` | 어드민 대시보드 |
| `geocode_api.dart` | 주소→좌표 변환 |
| `ai_chat_api.dart` | AI 채팅 |
| `ads_api.dart` | 광고/프로모션 배너 |

---

## 5. 핵심 기능

### 온보딩 플로우

```
앱 최초 실행
  ↓
권한 요청 (위치, 알림) — PermissionScreen
  ↓
약관 동의 — TermsScreen
  ↓
휴대폰 인증 (SMS) — PhoneVerifyScreen
  ↓
추천인 등록 (선택) — ReferrerScreen
  ↓
홈 화면 — MainScaffold
```

`OnboardingService`가 각 단계 완료 여부를 `SharedPreferences`에 저장하며, 이후 실행 시 바로 홈으로 이동합니다.

### 대리호출 (CallMapScreen)

- **카카오맵** (`kakao_maps_flutter`) 기반 지도 표시
- **현재 위치** 자동 감지 (`geolocator`) → 출발지 좌표 설정
- 목적지 검색: `DestinationSearchScreen` → 카카오 Local API
- 요금제 선택: 프리미엄 / 빠른 / 일반 (`FareType`)
- 결제 수단 선택: 현금 / 마일리지 / 등록카드 / 앱결제(카카오페이·토스)
- 요금 견적 API 호출 후 최종 호출 확정

### 결제 (PaymentScreen)

- **포트원 v2** (`portone_flutter_v2`) PG 연동
- 카드 빌링키 등록: `PortoneBillingKeyWebview` 위젯 활용
- 생체인증 연동: 첫 결제 후 다음 결제부터 지문/Face ID로 간편 인증 (`BiometricPaymentService`)
- 결제 화면 진입 시 스크린샷 방지 활성화 (`SecurityService.enableScreenshotProtection`)

### 인증 & 토큰 관리

- `TokenStorage`: `flutter_secure_storage`로 JWT access/refresh 토큰 암호화 저장
- `AuthService`: getAccessToken, refreshToken, logout, saveTokens
- refresh 실패 시 자동으로 `/phone-verify` 화면으로 이동 (전역 `onAuthRequired` 콜백)

### 보안 (SecurityService)

`flutter_security_suite` 패키지 기반:
- Root / Jailbreak 감지
- 에뮬레이터 감지
- 앱 변조 감지
- 런타임 후킹 감지
- 스크린 녹화 감지 및 스크린샷 방지

---

## 6. 주요 의존성 패키지

| 패키지 | 용도 |
|---|---|
| `dio` | HTTP 클라이언트 |
| `flutter_secure_storage` | 토큰 암호화 저장 |
| `shared_preferences` | 온보딩 상태 저장 |
| `kakao_maps_flutter` | 카카오 지도 |
| `geolocator` | GPS 위치 |
| `portone_flutter_v2` | PG 결제 (포트원 v2) |
| `local_auth` | 생체인증 (지문/Face ID) |
| `flutter_security_suite` | 보안 감지 (루트, 에뮬, 변조) |
| `connect_secure` | SSL 핀닝 |
| `flutter_dotenv` | .env 환경변수 |
| `permission_handler` | OS 권한 요청 |
| `url_launcher` | 외부 링크 열기 |
| `share_plus` | 앱 링크 공유 |
| `google_fonts` | 폰트 |
| `phosphor_flutter` | 아이콘 |
| `gap` | 여백 위젯 |
| `skeletonizer` | 스켈레톤 로딩 UI |
| `flutter_animate` | 애니메이션 |
| `flutter_inappwebview` | 인앱 웹뷰 |
| `connectivity_plus` | 네트워크 연결 감지 |
| `encrypt` | 데이터 암호화 |

---

## 7. 홈 화면 구성 (HomeScreen)

```
TopBar (햄버거 메뉴 + 로고 + 전화번호)
  ↓
공지사항 텍스트 배너
  ↓
접수 방법 선택 안내 + 마일리지 표시
  ↓
[24시간 앱 접수] 메인 카드 → CallMapScreen 이동
  ↓
[전화로 부르기] + [플라워] 2단 카드
  ↓
친구 초대 배너 (10,000원 + 2,000원 혜택)
  ↓
[이용내역] [친구추천] [마일리지] 3단 바로가기
  ↓
하단 네비바: 공지사항 / 출금신청 / 불편신고 / 카드등록 / 이벤트
```

사이드 드로어 메뉴: 공지사항, FAQ, 카드관리, 운행내역, 마일리지, 쿠폰, 사고/과태료, 고객센터, 추천인 등록/현황, 알림설정, 계정삭제

---

## 8. 환경 설정

- `.env` 파일 (gitignore) 또는 `assets/env_defaults.env` fallback
- 주요 환경변수: `API_CERT_PIN` (SSL 핀닝용 인증서 fingerprint)
- 카카오맵 API 키: `config/kakao_config.dart`
- 포트원 설정: `config/portone_config.dart`
- Debug 시 `adb reverse tcp:5174 tcp:5174` 필요 (`scripts/adb_reverse.bat`)

---

## 9. 작업 이력 (이번 세션 기준)

현재까지 진행된 주요 작업:

- **앱 구조 전반 설계 및 구현**
  - 온보딩 플로우 (권한→약관→전화인증→추천인)
  - 홈 화면 및 메인 스캐폴드(드로어) 구성
  - 대리호출 화면 (카카오맵, 위치, 요금 견적, 호출)
  - 다중 결제 수단 지원 (현금/마일리지/카드/카카오페이/토스)
- **API 레이어 정비**
  - JWT 자동 갱신 인터셉터 구현
  - SSL 핀닝 (Release 모드)
  - 광고 API (`AdsApi`) 추가 (단일/리스트 응답 모두 대응)
- **보안 강화**
  - 앱 시작 시 Root/에뮬/변조 감지
  - 결제 화면 스크린샷 방지
  - 생체인증 연동 (지문/Face ID)
- **관리자 화면 (어드민)**
  - 대시보드, 고객·기사 목록/상세, 운행 목록, 출석, 청구서, 요금 설정

---

