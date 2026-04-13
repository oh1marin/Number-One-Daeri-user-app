# Flutter 앱 · 스토어 없이 설치(APK/IPA) 시 API 베이스 URL 설정

스토어 배포 없이 APK/IPA만 설치해 쓰는 경우에도, **앱이 붙는 백엔드 공개 URL만 해당 배포 환경과 맞으면** 동일하게 기능이 동작할 수 있습니다. (앱 스토어 심사와 무관)

---

## 1. 백엔드에서 알아야 할 것

### 공개 API 베이스 URL

- **형식**: `https://<배포-도메인>/api/v1/`
- 이 레포(ride-be) 기준으로 HTTP 라우트는 **`/api/v1`** 아래에 마운트됩니다.

```64:64:src/app.ts
app.use('/api/v1', apiRouter);
```

- **예시 (일등대리 운영)**  
  - **과거에 쓰이던 1668 번호와 헷갈리기 쉬운 예전 API 도메인은 쓰지 않는다.** (대표 전화 **1668-0001** 같은 안내 문구는 그대로 두고, API 호스트만 배포 환경에 맞게 잡으면 된다.)
  - 프로덕션(HTTPS): `https://<운영-API-호스트>/api/v1/` — IDN이면 클라이언트·빌드에 맞게 Punycode URL을 쓸 수 있음
  - 프로덕션(IP·HTTP만 가능한 경우): `http://<API-서버-IP>/api/v1/` — Android는 cleartext 허용 설정이 필요할 수 있음
  - 로컬 백엔드: `http://127.0.0.1:5174/api/v1/` (`.env`의 `PORT`에 맞춤; 기본 5174)
  - **주의**: 관리자 웹과 API 호스트가 다르면, Flutter에는 **API가 실제로 떠 있는 URL**을 넣어야 한다.

### `/api/v1` 밖에 있는 엔드포인트 (참고)

- **헬스체크**: `GET /health` — 연결·배포 확인용으로 쓸 수 있음 (프리픽스 없음)
- **공지 웹 폴백**: `/notices` — 앱이 전부 `/api/v1`만 쓰면 일반적으로 무관

Flutter 쪽에서는 **앱이 호출하는 경로가 모두 `.../api/v1/...`로 시작하는지** 한 번 확인하면 됩니다.

---

## 2. Flutter에서 할 일: `apiBaseUrl` 맞추기

프로젝트에서 보통 `lib/config/api_config.dart`(또는 동일 역할 파일)에 베이스 URL이 정의되어 있습니다.

- **Release 빌드**: 운영 백엔드 `https://.../api/v1/` (끝 슬래시 규칙은 프로젝트 컨벤션에 맞출 것)
- **Debug 빌드**: 로컬 `http://127.0.0.1:5174/api/v1/` 등 개발 서버 주소

**배포 도메인이 바뀌면** 이 값을 새 URL로 바꾸거나, `--dart-define` / flavor / 환경별 설정으로 **환경마다 다른 `apiBaseUrl`**을 쓰면 됩니다.

### 이 레포에서 `--dart-define` (구현됨)

`lib/config/api_config.dart`에서 **`API_BASE_URL`**이 비어 있지 않으면 그 값을 쓰고, 비어 있으면 기존처럼 Release/Debug 기본값을 씁니다.

```bash
# 예: 운영 API로 APK 빌드 (호스트는 팀에서 공유한 실제 값으로 교체)
flutter build apk --release --dart-define=API_BASE_URL=https://<운영-API-호스트>/api/v1/

# 예: 실기기에서 디버그 실행 시 배포 서버로 붙이기
flutter run --dart-define=API_BASE_URL=https://<운영-API-호스트>/api/v1/

# 예: API를 IP·HTTP로만 쓸 때 (cleartext 설정 필요할 수 있음)
flutter run --dart-define=API_BASE_URL=http://<API-서버-IP>/api/v1/
```

- URL 끝의 `/`는 있어도 없어도 됩니다 (없으면 자동으로 붙음).
- 인증서 핀닝(`API_CERT_PIN`)을 켠 Release 빌드는 **새 도메인 인증서**에 맞게 핀을 다시 맞추거나, 전환 시 핀을 비워 두세요.

### Android: IP·HTTP(cleartext)

`android/app/src/main/res/xml/network_security_config.xml`에서 HTTP를 쓸 호스트(IP 또는 도메인)를 **직접 추가**하세요. 저장소 기본값에는 특정 IP가 들어 있지 않습니다.

---

## 3. HTTPS vs HTTP

- 운영은 **HTTPS**를 권장합니다. 배포가 HTTPS면 별도 조치 없이 일반적으로 동작합니다.
- Android에서 **HTTP(cleartext)** 만 쓰는 경우에는 `AndroidManifest` / 네트워크 보안 설정 등으로 **cleartext 허용**이 필요할 수 있습니다. (디버그·내부망 한정 권장)

---

## 4. 인증서 핀닝 (Certificate pinning)

Release 빌드에서 `.env` 등으로 **`API_CERT_PIN`**(또는 동일 목적 설정)을 켜 두었다면:

- **도메인 또는 인증서가 바뀌면** 새 체인에 맞게 핀을 **다시 설정**해야 합니다.
- 전환 기간에는 핀을 비우거나 비활성화해 두고, 확정된 도메인·인증서로 다시 핀을 거는 방식도 가능합니다.

핀닝을 쓰지 않으면 이 항목은 해당 없음입니다.

---

## 5. 체크리스트 (Flutter / 배포 담당)

| 항목 | 확인 |
|------|------|
| 운영 API 베이스 URL이 `https://<도메인>/api/v1/` 형태로 맞는가 | |
| Release `apiBaseUrl`이 위 URL과 일치하는가 | |
| (선택) `GET https://<도메인>/health` 로 서버 가동 확인 | |
| HTTPS 사용 시 인증서 오류 없음 | |
| HTTP만 쓰는 Android 빌드 시 cleartext 설정 | |
| 인증서 핀닝 사용 시 새 도메인/인증서 반영 | |

---

## 6. 요약

- **스토어 여부와 무관**하게, **앱의 API 베이스 URL = 실제 배포된 백엔드의 `/api/v1/` prefix**만 맞으면 해당 환경에서 동작 가능합니다.
- 도메인과 prefix를 확정한 뒤 Flutter의 `apiBaseUrl`(및 핀닝·cleartext)만 그에 맞게 조정하면 됩니다.

문의 시 **사용 중인 정확한 API 베이스 URL 한 줄**(프로토콜 + 호스트 + `/api/v1/` 포함 여부)을 백엔드와 공유하면 설정 충돌을 줄일 수 있습니다.
