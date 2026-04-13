# 공지사항 — Flutter 앱 연동

관리자 페이지에서 등록한 공지가 Flutter 앱에 보이려면 **백엔드 공개 API**와 **Flutter API 호출**이 필요합니다.

---

## 1. 백엔드: 공개 조회 API 필요

| 항목 | 내용 |
|------|------|
| **URL** | `GET /api/v1/notices` 또는 `GET /notices` |
| **인증** | **불필요** (공개) |
| **설명** | 관리자에서 등록된 공지 목록을 앱/웹에서 조회 |

**중요**: `GET /admin/notices`는 **관리자 전용(인증 필요)** 이므로 Flutter 앱에서는 **공개 API**를 사용해야 합니다.

```http
GET /api/v1/notices
Host: your-api-server.com
```

---

## 2. 응답 형식

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "clx123...",
        "badge": "공지",
        "badgeColor": "bg-red-100 text-red-600",
        "title": "2026년 연말 이벤트 안내",
        "date": "2026.12.01",
        "views": 1240,
        "content": "본문 내용...",
        "events": [
          {
            "title": "첫 이용 20% 할인",
            "date": "2026.12.01 ~ 12.31",
            "desc": "설명"
          }
        ]
      }
    ]
  }
}
```

또는 배열만:

```json
{
  "items": [ ... ]
}
```

---

## 3. Flutter에서 할 일

### 3.1 API 호출

```dart
// 예: Dio 사용 시
final response = await dio.get('$baseUrl/api/v1/notices');
// 또는
final response = await dio.get('$baseUrl/notices');
```

- `baseUrl`: Flutter 앱의 API 서버 주소 (웹·관리자와 동일)

### 3.2 응답 파싱

```dart
final data = response.data;
final items = data['data']?['items'] ?? data['items'] ?? data ?? [];
// items는 List<dynamic>
```

### 3.3 모델 (선택)

```dart
class Notice {
  final String id;
  final String badge;
  final String badgeColor;
  final String title;
  final String date;
  final int views;
  final String content;
  final List<NoticeEvent> events;

  Notice.fromJson(Map<String, dynamic> json)
    : id = json['id']?.toString() ?? '',
      badge = json['badge']?.toString() ?? '공지',
      badgeColor = json['badgeColor']?.toString() ?? 'bg-red-100 text-red-600',
      title = json['title']?.toString() ?? '',
      date = json['date']?.toString() ?? '',
      views = int.tryParse(json['views']?.toString() ?? '0') ?? 0,
      content = json['content']?.toString() ?? '',
      events = (json['events'] as List?)?.map((e) => NoticeEvent.fromJson(e)).toList() ?? [];
}
```

---

## 4. 체크리스트

- [ ] **백엔드**: `GET /api/v1/notices` (또는 `/notices`) 공개 API 구현
- [ ] **백엔드**: `/admin/notices`에 저장된 데이터와 동일한 공지 반환
- [ ] **Flutter**: 공지 화면에서 위 API 호출
- [ ] **Flutter**: 하드코딩된 공지 제거 → API 응답으로 대체
- [ ] **Flutter**: `baseUrl`이 관리자/웹과 같은 API 서버를 가리키는지 확인

---

## 5. 문제 해결

| 증상 | 확인 |
|------|------|
| 앱에 공지 안 보임 | Flutter가 실제로 API를 호출하는지, Network 로그 확인 |
| 404 에러 | 백엔드에 공개 `GET /notices` 경로 존재 여부 확인 |
| 401/403 | 공개 API는 인증 불필요. `/admin/notices` 대신 `/notices` 사용 |
| 빈 목록 | DB에 공지가 있는지, `GET /admin/notices`로 관리자 쪽 응답 확인 |
