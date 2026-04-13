# 보안 플러그인 (flutter_security_suite)

## 개요

`flutter_security_suite` 패키지를 사용하여 모바일 앱 보안 강화.

| 기능 | Android | iOS |
|------|---------|-----|
| Root/Jailbreak 감지 | ✅ | ✅ |
| 에뮬레이터 감지 | ✅ | ✅ |
| 스크린 녹화 감지 | ✅ | ✅ |
| 앱 변조 감지 | ✅ | ✅ |
| 런타임 훅 감지 (Frida 등) | ✅ | ✅ |
| 앱 무결성 검증 | ✅ | ✅ |
| 스크린샷 방지 | ✅ | ✅ |
| 인증서 핀닝 | ✅ | ✅ |

---

## 사용법

### 1. 앱 시작 시 보안 검사

`main.dart`에서 앱 시작 시 자동 실행. 위협 감지 시 디버그 로그 출력.

### 2. 결제 화면 스크린샷 방지

`PaymentScreen` 진입 시 `SecurityService.enableScreenshotProtection()` 호출, 
화면 이탈 시 `disableScreenshotProtection()` 호출.

### 3. 직접 보안 검사

```dart
final result = await SecurityService.runSecurityCheck();
if (!result.secure) {
  // result.isRooted, result.isEmulator, result.isTampered 등 확인
}
```

---

## 설정

### iOS

`Info.plist`에 Cydia URL 스킴 추가 (jailbreak 감지용):

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>cydia</string>
</array>
```

### Android

- minSdk: 23+ (기본값)
- 별도 권한 불필요 (스크린샷 방지는 FLAG_SECURE 사용)

---

## 시크릿 키 관리 (flutter_dotenv)

- `assets/env_defaults.env`: 기본 키 (빌드에 포함)
- `.env`: 로컬 개발용 (gitignore, `.env.example` 복사 후 채우기)
- 프로덕션: `--dart-define=KAKAO_MAP_API_KEY=xxx` 등으로 오버라이드 권장

---

## API 인증서 핀닝 (connect_secure)

Release 빌드에서 `assets/env_defaults.env`의 `API_CERT_PIN`에 **현재 `apiBaseUrl` 호스트**와 맞는 SPKI SHA-256을 설정하면 MITM 방지.

해시 추출:
```bash
openssl s_client -connect <API-호스트>:443 -servername <API-호스트> 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform DER \
  | openssl dgst -sha256 -binary \
  | base64
```

비워두면 핀닝 미적용 (기본 동작).

---

## flutter_security_suite 인증서 핀닝 (별도)

API 호스트 SPKI SHA-256 해시를 설정하면 MITM 공격 방지:

```dart
SecureBankKit.initialize(
  enablePinning: true,
  certificatePins: {
    'api.example.com': ['sha256/AAAAAAAA...'],
  },
);
```

### 변조 감지 시그니처

릴리즈 서명 후 `kit.tamperDetection.getSignatureHash()`로 SHA-256 해시를 조회해 설정.
