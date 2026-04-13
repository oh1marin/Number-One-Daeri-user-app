# Flutter 앱 연동 가이드

> 백엔드 API 연동 시 필요한 정보 모음

---

## 1. Base URL

| 환경 | Base URL |
|------|----------|
| 로컬 (PC) | `http://localhost:5174/api/v1` |
| Android 에뮬레이터 | `http://10.0.2.2:5174/api/v1` |
| iOS 시뮬레이터 | `http://localhost:5174/api/v1` |
| 실서버 | `https://your-domain.com/api/v1` |

**Flutter 공통 설정:**
```dart
// 환경별 분기
const String baseUrl = kReleaseMode
  ? 'https://your-domain.com/api/v1'
  : 'http://10.0.2.2:5174/api/v1';  // Android 에뮬
```

---

## 2. 인증 흐름

### 2.1 회원가입

```
POST /auth/register
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123",
  "name": "홍길동"
}

Response 201:
{
  "success": true,
  "data": {
    "admin": { "id": "cuid", "email": "...", "name": "..." },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}

Error 409: "이미 가입된 이메일입니다."
Error 400: "email, password, name 필수"
```

### 2.2 로그인

```
POST /auth/login
Content-Type: application/json

Request:
{
  "email": "user@example.com",
  "password": "password123"
}

Response 200:
{
  "success": true,
  "data": {
    "admin": { "id": "...", "email": "...", "name": "..." },
    "accessToken": "eyJhbGc...",
    "refreshToken": "eyJhbGc..."
  }
}

Error 401: "이메일 또는 비밀번호가 잘못되었습니다."
```

### 2.3 토큰 저장 및 사용

- **accessToken**: 모든 API 요청 시 `Authorization: Bearer <accessToken>` 헤더에 포함
- **refreshToken**: accessToken 만료 시 갱신에 사용
- **저장 권장**: `flutter_secure_storage` 등으로 accessToken, refreshToken 저장

### 2.4 토큰 갱신

```
POST /auth/refresh
Content-Type: application/json

Request:
{ "refreshToken": "eyJhbGc..." }

Response 200:
{
  "success": true,
  "data": { "accessToken": "eyJhbGc..." }
}
```

### 2.5 내 정보 조회

```
GET /auth/me
Authorization: Bearer <accessToken>

Response 200:
{
  "success": true,
  "data": { "id": "...", "email": "...", "name": "..." }
}
```

---

## 3. API 요청 공통

### 헤더

| 헤더 | 필수 | 설명 |
|------|------|------|
| Content-Type | O | `application/json` |
| Authorization | O (인증 API 제외) | `Bearer <accessToken>` |

### 응답 포맷

**성공**
```json
{ "success": true, "data": { ... } }
```

**실패**
```json
{ "success": false, "error": "에러 메시지" }
```

**HTTP 상태 코드**
- 200: 성공
- 201: 생성 성공
- 400: 잘못된 요청
- 401: 인증 필요 / 토큰 만료
- 404: 없음
- 409: 충돌 (중복 등)
- 500: 서버 에러

---

## 4. API 엔드포인트 목록

### 인증 (공개 — Authorization 불필요)
| Method | Path | 설명 |
|--------|------|------|
| POST | /auth/register | 회원가입 |
| POST | /auth/login | 로그인 |
| POST | /auth/refresh | 토큰 갱신 |
| GET | /auth/me | 내 정보 |

### 대시보드
| Method | Path | 설명 |
|--------|------|------|
| GET | /dashboard | 오늘 건수/매출, 최근 내역, 기사별 현황 |

### 고객
| Method | Path | 설명 |
|--------|------|------|
| GET | /customers | 목록 (?field=name&q=검색어) |
| GET | /customers/:id | 단건 |
| GET | /customers/:id/rides | 운행 이력 |
| POST | /customers | 등록 |
| PUT | /customers/:id | 수정 |
| DELETE | /customers/:id | 삭제 |

### 기사
| Method | Path | 설명 |
|--------|------|------|
| GET | /drivers | 목록 |
| GET | /drivers/:id | 단건 |
| GET | /drivers/:id/rides | 운행 이력 |
| POST | /drivers | 등록 |
| PUT | /drivers/:id | 수정 |
| DELETE | /drivers/:id | 삭제 |

### 운행(콜)
| Method | Path | 설명 |
|--------|------|------|
| GET | /rides | 목록 (?date=, ?driverName=, ?field=, ?q=) |
| GET | /rides/:id | 단건 |
| POST | /rides | 신규 콜 |
| PUT | /rides/:id | 수정 |
| DELETE | /rides/:id | 삭제 |

### 근태
| Method | Path | 설명 |
|--------|------|------|
| GET | /attendance | 월별 (?year=2026&month=3) |
| POST | /attendance | 단일 셀 저장 |
| PUT | /attendance/:driverId/:year/:month | 월 전체 upsert |
| DELETE | /attendance/:driverId/:year/:month | 월 전체 삭제 |

### 세금계산서
| Method | Path | 설명 |
|--------|------|------|
| GET | /invoices | 목록 |
| GET | /invoices/:id | 단건 |
| GET | /invoices/settings | 공급자 설정 |
| POST | /invoices | 등록 |
| PUT | /invoices/:id | 수정 |
| PUT | /invoices/settings | 공급자 설정 저장 |
| DELETE | /invoices/:id | 삭제 |

### 요금 설정
| Method | Path | 설명 |
|--------|------|------|
| GET | /settings/fares | 지역·요금 행렬 |
| PUT | /settings/fares | 지역·요금 행렬 저장 |

---

## 5. 주요 DTO 예시 (Flutter용)

### Admin
```dart
class Admin {
  final String id;
  final String email;
  final String name;
  Admin({required this.id, required this.email, required this.name});
  factory Admin.fromJson(Map<String, dynamic> json) =>
    Admin(id: json['id'], email: json['email'], name: json['name']);
}
```

### AuthResponse
```dart
class AuthResponse {
  final Admin admin;
  final String accessToken;
  final String refreshToken;
  AuthResponse({required this.admin, required this.accessToken, required this.refreshToken});
  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    admin: Admin.fromJson(json['admin']),
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
  );
}
```

### Customer
```dart
class Customer {
  final String id;
  final int no;
  final String name;
  final String? phone;
  final String? mobile;
  final String category;
  // ... 기타 필드
}
```

### Ride
```dart
class Ride {
  final String id;
  final String date;      // YYYY-MM-DD
  final String time;      // HH:mm
  final String customerName;
  final String driverName;
  final String pickup;
  final String dropoff;
  final int fare;
  final int discount;
  final int extra;
  final int total;
}
```

---

## 6. HTTP 클라이언트 예시 (Dio)

```dart
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:5174/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static void setToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  static Future<Response> get(String path) => _dio.get(path);
  static Future<Response> post(String path, dynamic data) => _dio.post(path, data: data);
  static Future<Response> put(String path, dynamic data) => _dio.put(path, data: data);
  static Future<Response> delete(String path) => _dio.delete(path);
}
```

---

## 7. 401 처리 (토큰 만료)

1. API 응답 401 수신
2. `POST /auth/refresh` 로 accessToken 갱신 시도
3. 성공 시 새 accessToken 저장 후 원래 요청 재시도
4. 실패 시 로그인 화면으로 이동
