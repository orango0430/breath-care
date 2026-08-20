# BPACE (Breath Care) 🫁

> **중요한 순간을 미리 알아채고, 내 컨디션에 맞춰 이끄는 맞춤 호흡 리추얼**

BPACE는 예측, 측정, 리추얼 세 단계를 하나의 흐름으로 연결합니다.

먼저 사용자의 캘린더 일정을 읽어 시험, 면접, 발표처럼 컨디션이 중요한 순간을 자동으로 감지합니다. 별도의 입력 없이도 일정 제목의 키워드를 기반으로 다가올 순간을 미리 파악하고, 해당 시점 전에 준비를 제안하는 알림을 보냅니다.

다음으로 워치 같은 웨어러블 기기 없이, 스마트폰 후면 카메라와 플래시만으로 손끝의 혈류 변화를 20초간 분석해 심박수와 심박변이도를 측정합니다. 스마트폰 카메라 기반 생체 신호 측정은 임상 심전도와 96% 이상의 상관관계를 보인다는 연구 결과가 있어, 워치 없이도 신뢰할 수 있는 방식으로 컨디션을 확인할 수 있습니다.

마지막으로 측정된 상태를 바탕으로 리추얼이 시작됩니다. 리추얼은 사용자가 컨디션을 확인한 뒤 진행하는 호흡 세션으로, 정해진 속도를 처음부터 강요하지 않고 사용자의 현재 상태에서 출발해 목표 리듬까지 점진적으로 조율됩니다. 시각적 가이드와 사운드가 들숨과 날숨에 맞춰 함께 재생되어, 사용자는 화면을 보며 자연스럽게 호흡을 따라갈 수 있습니다.

이렇게 예측, 측정, 리추얼이 하나로 이어지면서, 사용자는 스스로 찾아 나서지 않아도 필요한 순간에 맞춰 준비된 컨디션으로 임할 수 있습니다.

---

## 핵심 기능

### 1. 예측 — 일정을 읽고 미리 알린다

캘린더에 등록된 일정을 시험·발표·면접·마감으로 구분해 두면, 서버가 매분 발송 대상을 확인해 두 번 알림을 보냅니다. **전날 밤 22시**에는 "내일 시험이 있어요"와 함께 잠들기 좋은 호흡을, **일정 30분 전**에는 그 순간에 맞는 호흡을 권합니다. 폰 캘린더와의 동기화도 지원해 손으로 넣은 일정은 건드리지 않으면서 몇 번을 실행해도 결과가 같도록 맞춰 두었습니다.

알림 문구는 일정 종류와 시점에서 만들어집니다. 전날 밤은 종류를 가리지 않고 날숨이 가장 긴 4-7-8 호흡을, 직전 30분은 발표면 생리학적 한숨, 시험이면 박스 호흡, 면접이면 공진 호흡으로 갈라집니다.

### 2. 측정 — 카메라와 플래시로 20초

후면 카메라에 손끝을 대면 플래시를 켜고 프레임의 밝기 변화를 20초간 모읍니다. 앱은 손가락이 실제로 닿아 있는 구간만 골라 서버로 올리고, 서버는 대역통과 → 관류 확인 → 피크 검출 → 포물선 보간 → 이상치 제거를 거쳐 **심박수(HR)와 심박변이도(SDNN·RMSSD)** 를 냅니다. 30fps에서 피크를 프레임 단위로만 잡으면 HRV의 상당 부분이 양자화 잡음이 되기 때문에, 봉우리 좌우 세 점에 포물선을 맞춰 프레임 사이 위치까지 추정합니다.

측정 결과는 **컨디션 지수(0~100)** 로 환산됩니다. HRV 하나를 로그 척도로 옮기는 방식이라 개인 기준선이 쌓이기를 기다릴 필요 없이 첫 측정부터 값이 나옵니다. 신호가 나쁘면 숫자를 만들어내지 않고 어느 단계에서 걸렸는지 사유를 돌려주며 재측정을 요청합니다. 로그인 없이도 `POST /api/measurements/analyze`로 회원과 완전히 같은 계산을 받아볼 수 있고, 이 경로는 아무것도 저장하지 않습니다.

### 3. 리추얼 — 내 호흡에서 출발해 목표 리듬까지

측정된 심박수와 HRV로 다섯 갈래 중 하나가 정해집니다. 심박이 95 이상이면 생리학적 한숨, 60 미만이면 각성 호흡, HRV가 30ms 미만이면 4-7-8, 55ms 미만이면 박스 호흡, 그 이상이면 공진 호흡입니다.

측정 결과에서 이어지는 세션은 **처음부터 목표 속도를 강요하지 않습니다.** 방금 잰 호흡 주기에서 출발해 90초에 걸쳐 목표 템포까지 옮겨 가고, 템포는 주기가 바뀌는 순간에만 갱신되어 호흡 중간에 리듬이 흔들리지 않습니다. 화면의 시각 가이드와 호흡법별 사운드가 들숨·날숨에 맞춰 함께 갑니다. 세션이 끝나면 다시 재서 전후를 한 쌍으로 남기고, 쌓인 기록은 주간 통계와 AI 리포트로 이어집니다.

### 그 외

- **기록·통계** — 일별 심박수·HRV·컨디션 지수 추이와 기간 요약
- **주간 AI 리포트** — OpenAI 또는 Gemini로 생성. 조회는 저장된 것만 주고, 측정 3회 미만이면 호출하지 않으며, 재생성은 6시간 간격으로 묶어 사용량을 아낍니다
- **인증** — 이메일 가입·로그인과 구글 소셜 로그인(JWT)

---

## 실행 방법

### 요구 사항

| 대상 | 필요한 것 |
| :--- | :--- |
| 백엔드 | JDK 17, Docker (로컬 MySQL 용) |
| 프론트엔드 | Flutter SDK 3.x, Android 실기기 (카메라·플래시가 필요해 에뮬레이터로는 측정이 안 됩니다) |

### 백엔드 (Spring Boot)

```bash
# 1. MySQL 컨테이너 기동 (호스트 3307 포트를 씁니다)
docker compose up -d

# 2. 앱 실행 — 기본 프로필은 local, http://localhost:8080
./gradlew bootRun

# 3. 확인
curl http://localhost:8080/api/breathing/presets
```

`local` 프로필은 JWT 시크릿과 DB 비밀번호에 개발용 기본값이 있어 **키 없이 그대로 뜹니다.** AI 리포트와 FCM 푸시만 꺼진 상태로 시작하고(리포트는 503), 켜려면 프로젝트 루트에 `.env`를 만들어 값을 넣습니다.

```bash
REPORT_PROVIDER=openai        # none | gemini | openai
OPENAI_API_KEY=...
FIREBASE_ENABLED=true         # firebase-service-account.json 필요
```

테스트:

```bash
./gradlew test
```

DB 스키마는 Flyway가 기동 시점에 적용하므로 따로 만들 것이 없습니다. 배포(Railway)는 [DEPLOY.md](DEPLOY.md)를 보세요.

### 프론트엔드 (Flutter)

```bash
cd frontend
flutter pub get

# 배포된 서버에 붙어서 실행 (기본값)
flutter run

# 로컬 백엔드에 붙이려면 — 안드로이드 에뮬레이터에서 호스트는 10.0.2.2
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

기본 `baseUrl`은 Railway 주소라 릴리스 APK는 추가 설정 없이 동작합니다. `http://` 주소로 바꿔 붙일 때는 안드로이드 9 이상에서 cleartext 예외가 필요합니다.

---

## 기술 스택

| 구분 | 사용 기술 |
| :--- | :--- |
| **백엔드** | Java 17, Spring Boot 4.1, Spring Security(JWT), JPA, Flyway, MySQL 8.4 |
| **프론트엔드** | Flutter 3, Material 3, camera, permission_handler, audioplayers, shared_preferences |
| **인증·푸시** | JWT, Google Sign-In, Firebase Cloud Messaging |
| **AI** | OpenAI / Gemini (교체 가능한 `ReportGenerator` 구현) |
| **배포** | Docker, Railway |

---

## 주요 API

| 메서드 | 경로 | 설명 |
| :--- | :--- | :--- |
| `POST` | `/api/auth/signup`, `/api/auth/login`, `/api/auth/social` | 가입·로그인·구글 로그인 (인증 불필요) |
| `POST` | `/api/measurements` | 파형 업로드 → HR·HRV·컨디션 지수 |
| `POST` | `/api/measurements/analyze` | 비회원 측정. 계산만 하고 저장하지 않음 (인증 불필요) |
| `GET` | `/api/breathing/presets` | 호흡법 8종과 초 단위 타이밍 (인증 불필요) |
| `POST` · `PATCH` | `/api/sessions`, `/api/sessions/{id}/complete` | 호흡 세션 시작·종료(전후 측정 연결) |
| `GET` · `POST` · `PUT` · `DELETE` | `/api/calendar/events` | 일정 CRUD |
| `POST` | `/api/calendar/sync` | 폰 캘린더 동기화 |
| `POST` · `DELETE` | `/api/devices` | FCM 토큰 등록·해제 |
| `GET` | `/api/statistics/summary`, `/api/statistics/daily` | 기간 요약·일별 추이 |
| `GET` · `POST` | `/api/reports/weekly` | 주간 AI 리포트 조회·생성 |

---

## 프로젝트 구조

```text
breath_care/
├── src/main/java/org/exaple/breath_care/
│   ├── user/           # 가입·로그인·소셜 인증
│   ├── calendar/       # 일정, 폰 캘린더 동기화, push/ 알림 스케줄러
│   ├── measurement/    # 측정 저장, signal/ 신호처리, score/ 컨디션 지수
│   ├── breathing/      # 호흡법 8종 프리셋과 추천 규칙
│   ├── session/        # 호흡 세션(전 측정 ↔ 후 측정)
│   ├── statistics/     # 기간 요약·일별 집계
│   ├── report/         # 주간 AI 리포트, generate/ 제공자별 구현
│   └── global/         # 보안, 예외, 공통 응답, Firebase 설정
├── src/main/resources/db/migration/   # Flyway 마이그레이션
└── frontend/lib/
    ├── screens/        # 측정·추천·호흡·기록 화면
    ├── services/       # API 클라이언트와 도메인별 서비스
    ├── utils/          # PPG 센서, 호흡 루틴 모델
    └── theme/          # 컬러·타이포그래피
```
