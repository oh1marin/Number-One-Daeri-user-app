# 카카오맵 설정 가이드

## ⚠️ 지도가 하얗게 보이거나 401 Unauthorized?

**Android 플랫폼 등록 + SHA-1 키 해시**가 꼭 필요합니다. 키만 넣으면 401 에러로 지도가 안 뜹니다.

---

## 0. SDK 요구사양 (확인됨)

| 항목 | 값 |
|------|-----|
| Android 플랫폼 | API 23 (6.0) 이상 |
| 아키텍처 | armeabi-v7a, arm64-v8a |
| OpenGL ES | 2.0 이상 |
| 권한 | `INTERNET` (필수) |

`android/app/build.gradle.kts`에 minSdk 23, ndk abiFilters 적용됨.  
`AndroidManifest.xml`에 `INTERNET` 권한 있음. Activity는 `hardwareAccelerated=true` (OpenGL 지원).

---

## 1. API 키 발급

1. [Kakao Developers Console](https://developers.kakao.com/console/app) 접속
2. 애플리케이션 생성 또는 선택
3. **앱 키** 탭 → **네이티브 앱 키** 확인/복사

## 2. Android 플랫폼 등록 (필수!)

1. **플랫폼** → **플랫폼** → **Android** 추가
2. **패키지명**: `com.example.number_one_daeri_user_app`
3. **키 해시**: 아래로 SHA-1 추출 후 등록

### SHA-1 추출 방법

**방법 1 – Gradle (권장)**

```powershell
cd android
.\gradlew signingReport
```

출력에서 `Variant: debug` → `SHA1:` 값 복사 (예: `AA:BB:CC:DD:...`).

**방법 2 – keytool**

```powershell
keytool -list -v -keystore $env:USERPROFILE\.android\debug.keystore -alias androiddebugkey -storepass android -keypass android
```

`SHA1` 지문 복사.

4. 카카오 콘솔 **키 해시** 란에 붙여넣고 저장

**방법 3 – Android Studio**
- 프로젝트 → Gradle → `android` → `Tasks` → `android` → `signingReport` 더블클릭
- Run 탭에서 `SHA1:` 출력 확인

---

## 3. 앱에 키 설정

`lib/config/kakao_config.dart` 파일을 열고:

```dart
const String kakaoMapApiKey = '발급받은_네이티브_앱_키';
```

`YOUR_KAKAO_NATIVE_APP_KEY` 를 실제 키로 교체하세요.

## 4. 사용 위치

- **24시간 앱 접수** 화면: 지도가 카카오맵으로 표시됩니다.
- API 키가 없으면 플레이스홀더가 표시됩니다.

## 5. 패키지

- `kakao_maps_flutter`: 카카오맵 SDK
- `geolocator`: 현재 위치 조회

## 6. 지도 라이프사이클 (주의)

카카오맵 문서: Activity `onResume`/`onPause` 시 `MapView.resume()`, `MapView.pause()` 호출 필수. 미호출 시 크래시 가능.

`kakao_maps_flutter` 공식 패키지는 아직 이를 자동 처리하지 않음. 앱 전환(백그라운드/포그라운드) 시 크래시가 발생하면 [패키지 이슈](https://github.com/seunghwanly/kakao_maps_flutter/issues)에 라이프사이클 지원을 요청하세요.

## 7. API 비동기 처리

지도 set 호출 직후 get으로 변경된 값을 가져오는 것은 **보장되지 않음**.  
카메라 변경 후 값이 필요하면 `controller.onCameraMoveEndStream` 또는 `onCameraMoveEnd` 콜백 사용.

## 8. 로고 표시 정책

카카오맵 API 사용 시 기본적으로 지도 우하단에 로고가 표시됨. **로고 숨김/가림은 허용되지 않음**.  
일시적으로 가려지는 경우는 허용. `hideLogo()` 호출 금지.

## 9. 커스텀 마커 이미지

지도에 사용하는 이미지는 `drawable-nodpi/` 에 넣는 것을 권장 (다양한 해상도에서 일정한 크기).

## 10. ProGuard (선택)

앱 배포 시 **코드 축소/난독화**를 사용하는 경우, `android/app/build.gradle.kts`에서 `release` 타입에 `isMinifyEnabled = true`를 설정한 뒤, `proguard-rules.pro`를 지정하세요.  
이미 `android/app/proguard-rules.pro`에 카카오맵 SDK 규칙이 추가되어 있습니다.

```kotlin
release {
    isMinifyEnabled = true
    proguardFiles(
        getDefaultProguardFile("proguard-android-optimize.txt"),
        "proguard-rules.pro"
    )
}
```

