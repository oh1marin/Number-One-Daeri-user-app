# 경유지(Waypoint) 기능 — 일등대리

출발지·도착지 사이에 **경유지**를 추가하는 기능입니다.  
앱 UI + 백엔드 API + 관리자 콜 목록 로그까지 포함합니다.

---

## 1. 사용자 흐름 (앱)

1. **대리호출** 화면에서 출발지 설정 (GPS / 검색)
2. 도착지 입력란 오른쪽 **「경유」** 탭 → **경유지 선택** 화면
3. 검색 후 **「경유」** 버튼으로 추가 (최대 **3곳**)
4. 추가된 경유지는 **「삭제」** 로 제거
5. 도착지 선택 후 요금 자동 재계산 (출발 → 경유들 → 도착 거리 합산)
6. **대리호출** 시 서버에 경유지·전체 경로 저장

### 관련 FE 파일

| 파일 | 역할 |
|------|------|
| `lib/screens/call/call_map_screen.dart` | 경유 상태·검색·호출 payload |
| `lib/screens/call/call_map_booking_panel.dart` | 출발/경유/도착 UI |
| `lib/screens/call/destination_search_screen.dart` | 출발·도착·경유 공용 검색 |
| `lib/models/ride_waypoint.dart` | 경유지 모델 |
| `lib/api/rides_estimate_api.dart` | 요금 견적 (경유 포함) |
| `lib/api/rides_call_api.dart` | 호출 생성 (경유 포함) |

### 관리자 웹 (`C:\project\ride-fe`)

| 파일 | 변경 |
|------|------|
| `apps/web-admin/app/order-status/page.tsx` | **경유** 열, **경로**(`routeSummary`) 열 |
| `apps/web-admin/app/mileage/ride-complete/page.tsx` | 경로 요약 + 경유 개수 |
| `packages/shared/src/types/ride.ts` | `RideWaypointDto`, `routeSummary` 타입 |


---

## 2. API (백엔드)

베이스: `/api/v1` (인증 필요 — `POST /rides/*`)

### 요금 견적 `POST /rides/estimate`

```json
{
  "originLatitude": 37.5,
  "originLongitude": 127.0,
  "destinationLatitude": 37.55,
  "destinationLongitude": 126.97,
  "waypoints": [
    {
      "sequence": 1,
      "name": "서울역",
      "address": "서울 용산구 …",
      "latitude": 37.554,
      "longitude": 126.97
    }
  ]
}
```

**응답:** `distanceKm` (구간 합), `waypointCount`, `fares.{normal,fast,premium}`

### 호출 생성 `POST /rides/call`

기존 필드 + 아래 추가:

```json
{
  "latitude": 37.5,
  "longitude": 127.0,
  "address": "출발지 주소",
  "destinationLatitude": 37.55,
  "destinationLongitude": 126.97,
  "destinationAddress": "도착지 주소",
  "waypoints": [ { "sequence": 1, "name": "…", "address": "…", "latitude": 37.5, "longitude": 127.0 } ],
  "estimatedDistanceKm": 12.3,
  "estimatedFare": 12300,
  "paymentMethod": "cash"
}
```

저장 시 DB에 `waypoints`(JSON), `routeSummary`(문자열) 기록.

### 관리자 목록 `GET /admin/rides`

각 항목에 추가 필드:

| 필드 | 설명 |
|------|------|
| `waypoints` | 경유지 배열 |
| `waypointCount` | 경유 개수 |
| `routeSummary` | `출발 → 경유1 → … → 도착` 한 줄 |

상세 `GET /admin/rides/:id` — Ride 전체 객체에 `waypoints`, `routeSummary` 포함.

### 관련 BE 파일

| 파일 | 역할 |
|------|------|
| `prisma/schema.prisma` | `Ride.waypoints`, `Ride.routeSummary` |
| `src/lib/rideWaypoints.ts` | 파싱·거리 합산·경로 문자열 |
| `src/routes/app/rides.ts` | estimate / call |
| `src/routes/rides.ts` | 관리자 목록 노출 |

---

## 3. DB 마이그레이션 (서버 배포 시 필수)

```bash
cd ride-be
git pull
npm run db:push    # 또는 migrate
npm run build
pm2 restart all    # 사용 중인 방식
```

추가 컬럼:

- `rides.waypoints` — JSON, nullable  
- `rides.routeSummary` — TEXT, nullable  

기존 운행 데이터는 `waypoints = null`, `routeSummary = null` 로 유지됩니다.

---

## 4. 제한·요금

- 경유지 **최대 3곳** (앱 UI 기준, API는 최대 5곳 파싱)
- 거리: 출발 → 경유1 → … → 도착 **직선(Haversine) 구간 합**
- 요금: 합산 거리 × km 단가 (기존 normal/fast/premium 동일)

---

## 5. 맥북 / 다른 PC에서 이어서 작업

```bash
# FE
cd ride_fe
git pull
flutter pub get

# BE
cd ride-be
git pull
npm install
npm run db:push
npm run build
```

테스트:

1. 앱 로그인 → 대리호출
2. 도착지 **경유** → 장소 선택 → 목록에 경유 행 표시
3. 도착지 선택 → km·요금에 경유 반영 확인
4. 호출 후 관리자 **콜 목록**에서 `routeSummary` 확인

---

## 6. 향후 개선 (미구현)

- 지도에 경유 핀 표시
- 카카오/네이버 **실제 경로** 기반 거리 (현재는 직선 합산)
- 운행내역 화면에 경유지 표시
- 경유지별 추가 요금 정책

---

*최종 업데이트: 2026-07-07*
