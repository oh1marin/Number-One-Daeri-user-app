# Number-One-Daeri-user-app

## Firebase (Android)

`android/app/google-services.json`은 **저장소에 커밋하지 않습니다**. (로컬/CI에서만 주입)

- 로컬: Firebase 콘솔에서 다운로드한 `google-services.json`을 `android/app/`에 두고 빌드
- CI: 시크릿에 파일 내용을 저장한 뒤, 빌드 전에 `android/app/google-services.json`으로 생성