# 대리호출 옵션 — 백엔드 전달사항

앱에서 **대리호출** 시 사용자가 선택하는 옵션을 `POST /rides/call` Body에 함께 보냅니다.  
백엔드에서는 이 값을 저장해 관리자 페이지에서 조회·배차에 활용하면 됩니다.

---

## 1. 옵션 필드 (Body 추가)

| 필드 | 타입 | 필수 | 값 | 설명 |
|------|------|------|-----|------|
| transmission | string | 선택 | `auto` \| `stick` | 오토 / 스틱 |
| serviceType | string | 선택 | `daeri` \| `taksong` | 대리운전 / 탁송 |
| quickBoard | string | 선택 | `possible` \| `impossible` | 퀵보드 가능 / 불가 |
| vehicleType | string | 선택 | `sedan` \| `9seater` \| `12seater` \| `cargo1t` | 승용차 / 9인승 / 12인승 / 화물 1톤 |

- 앱에서 **옵션 선택 화면**을 거친 경우에만 위 필드가 포함됩니다.
- 전화 접수 등 다른 경로로 들어온 콜은 이 필드가 없을 수 있으므로 **선택(optional)** 처리하면 됩니다.

---

## 2. POST /rides/call Body 예시

```json
{
  "latitude": 37.123,
  "longitude": 127.456,
  "address": "경기도 평택시 용이동 737",
  "addressDetail": "서울역",
  "phone": "16680001",
  "transmission": "auto",
  "serviceType": "daeri",
  "quickBoard": "possible",
  "vehicleType": "sedan"
}
```

---

## 3. DB 저장 제안

- rides(또는 calls) 테이블에 컬럼 추가:
  - `transmission` (VARCHAR, nullable)
  - `service_type` (VARCHAR, nullable)
  - `quick_board` (VARCHAR, nullable)
  - `vehicle_type` (VARCHAR, nullable)
- 또는 JSON 컬럼 하나에 `{ "transmission", "serviceType", "quickBoard", "vehicleType" }` 저장 후 관리자에서 파싱해 표시.

---

## 4. 관리자 페이지 표시 제안

- 콜 목록/상세에 예시처럼 표시하면 됩니다.
  - 변속기: 오토 / 스틱
  - 유형: 대리운전 / 탁송
  - 퀵보드: 가능 / 불가
  - 차량: 승용차 / 9인승 / 12인승 / 화물 1톤

값 매핑은 위 표의 그대로 사용하면 됩니다.
