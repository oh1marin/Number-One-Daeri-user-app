# 카카오맵 API - FE 전달 사항

일등대리 앱(Flutter)에서 사용하는 카카오맵 설정 및 참고용 문서입니다.

---

## 1. API 키

| 용도 | 키 위치 | 용도 |
|------|---------|------|
| **네이티브 앱** (지도 표시) | `lib/config/kakao_config.dart` → `kakaoMapApiKey` | Android/iOS 지도 |
| **REST API** (장소/주소 검색) | `lib/config/kakao_config.dart` → `kakaoRestApiKey` | 검색 API |

발급: [카카오 개발자콘솔](https://developers.kakao.com/console/app) → 앱 선택 → 앱 키

---

## 2. 사용 화면

| 화면 | 파일 | 설명 |
|------|------|------|
| 대리호출 지도 | `lib/screens/call/call_map_screen.dart` | 출발·도착 핀, 경로선, 출발/도착/전체 전환 |
| 도착지 검색 | `lib/screens/call/destination_search_screen.dart` | 카카오 로컬 검색 |
| 전화 부르기 모달 | `lib/widgets/phone_call_modal.dart` | 현재 위치 지도 |

---

## 3. 필수 설정 (Android)

1. **플랫폼 등록**: 개발자콘솔 → 플랫폼 → Android 추가
2. **패키지명**: `com.example.number_one_daeri_user_app`
3. **키 해시(SHA-1)**: `./gradlew signingReport` 결과 등록

미등록 시 지도가 401로 표시되지 않음.

---

## 4. 패키지

```yaml
# pubspec.yaml
dependencies:
  kakao_maps_flutter: ^0.1.2
  geolocator: ^13.0.2
```

---

## 5. 핵심 구현 참고

- **초기화**: `main.dart`에서 `KakaoMapsFlutter.init(kakaoMapApiKey)` 호출
- **설정 상수**: `lib/config/kakao_config.dart`
- **장소 검색**: `lib/services/kakao_local_service.dart` (REST API)
- **상세 가이드**: 프로젝트 루트 `KAKAO_MAP_SETUP.md`
