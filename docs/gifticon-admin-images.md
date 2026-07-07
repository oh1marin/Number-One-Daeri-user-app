# 기프티콘 상점 이미지(관리자 업로드) 연동 가이드 (FE 전달용)

## 목표

- 관리자페이지에서 **기프티콘 상품 이미지**를 업로드/등록하면,
- 앱의 **기프티콘 상점(마일리지 교환)** 화면에서 해당 이미지가 노출되도록 한다.

이벤트/공지사항과 동일한 방식으로 동작한다.

---

## 동작 방식 요약

- 앱은 `GET /gifticon/products`에서 내려오는 상품 리스트를 사용한다.
- 각 상품에는 `imageUrl`(또는 `coverImageUrl`/`thumbnailUrl`) 필드를 포함할 수 있다.
- 앱은 이미지 URL이 **절대 URL**이면 그대로 사용하고,
  **상대 경로**이면 `apiBaseUrl` 기준으로 붙여서 완성 URL로 만든 후 표시한다.

상대경로 처리 함수는 이벤트/공지에서 이미 사용 중인 `resolveMediaUrl()`과 동일하다.

---

## 백엔드(관리자) 요구사항

### 1) 상품 조회 API에 이미지 URL 포함

`GET /api/v1/gifticon/products` 응답의 각 item에 아래 중 하나를 포함:

- `imageUrl` (권장)
- 또는 `coverImageUrl`
- 또는 `thumbnailUrl` / `thumbUrl`

예시:

```json
{
  "data": [
    {
      "id": "mega_americano_ice",
      "name": "아이스 아메리카노",
      "mileagePrice": 2000,
      "imageUrl": "/uploads/gifticon/mega_americano_ice.png"
    }
  ]
}
```

### 2) URL 형태

- **권장**: 절대 URL
  - 예: `https://api.example.com/uploads/gifticon/mega_americano_ice.png`
- **가능**: 상대 경로
  - 예: `/uploads/gifticon/mega_americano_ice.png`
  - 앱에서 `apiBaseUrl` 기준으로 자동 resolve 됨

> 주의: `apiBaseUrl`은 `/api/v1/`로 끝난다. 상대 경로를 사용할 때는
> `resolveMediaUrl()`이 `Uri.resolve()`로 합치므로, 서버가 주는 경로가 올바르게 합쳐지도록
> `/uploads/...` 같이 루트 기준 경로를 권장한다.

### 3) 이미지 접근

- 앱에서 바로 로드할 수 있도록 **public 접근 가능**해야 한다(토큰 필요하면 추가 작업 필요).

---

## 앱(Flutter) 변경 사항

### 1) 모델: 이미지 필드 추가

- 파일: `lib/models/gifticon.dart`
- 변경: `GifticonProduct`에 `String? imageUrl` 추가

### 2) API 파싱: imageUrl 필드 읽기

- 파일: `lib/api/gifticon_api.dart`
- 변경: `_productFromApi()`에서 아래 키를 순서대로 탐색
  - `imageUrl` → `coverImageUrl` → `thumbnailUrl` → `thumbUrl`
- 서버에 이미지가 없으면 로컬 카탈로그의 `imageUrl`(있다면) 사용

### 3) UI: 상품 썸네일에 이미지 표시

- 파일: `lib/widgets/gifticon/gifticon_widgets.dart`
- 변경: `_ProductThumb`에서
  - `resolveMediaUrl(product.imageUrl)`가 있으면 `AppNetworkImage`로 표시
  - 없으면 기존처럼 **브랜드 색 원 + 아이콘** 표시(폴백)

---

## 기대 결과(검증 포인트)

- 관리자에서 상품 이미지 등록 후
- 앱 `기프티콘 상점`에서 해당 상품 카드 상단 썸네일이 이미지로 표시됨
- 이미지가 없으면 기존 UI(아이콘)로 정상 표시됨
