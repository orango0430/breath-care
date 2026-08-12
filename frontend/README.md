# BPACE (Breath Care) 🫁

> 카메라 PPG 센서를 활용한 심박수 및 컨디션 측정 기반 맞춤형 호흡 케어 플러터(Flutter) 애플리케이션입니다.

---

## 📌 프로젝트 소개 (Project Overview)
**BPACE (Breath Care)**는 스마트폰 카메라 센서를 통해 사용자의 심박수(Heart Rate) 및 컨디션을 측정하고, 측정된 상태에 맞춰 최적화된 맞춤형 호흡 루틴(Box Breathing, 4-7-8 호흡법 등)을 안내하는 웰니스 라이프 케어 앱입니다.

---

## ✨ 주요 기능 (Key Features)

1. **스마트 심박수 및 컨디션 측정 (PPG Sensor Measurement)**
   - 카메라 렌즈와 플래시를 이용한 PPG(광혈류 측정) 기술 기반 심박수 측정 (`heart_bpm`, `camera`)
   - 실시간 측정 그래프 애니메이션 및 측정 신뢰도 가이드 제공
   - 측정 결과를 바탕으로 한 컨디션 점수 분석

2. **맞춤형 호흡 루틴 추천 (Personalized Breathing Routine)**
   - 측정된 컨디션 및 스트레스 지수에 따라 최적화된 호흡법 추천
   - 4-7-8 호흡, 박스 브리딩(Box Breathing), 딥 브리딩 등 다양한 호흡 가이드 제공

3. **인터랙티브 호흡 운동 인터페이스 (Guided Breathing Exercise)**
   - 들숨(Inhale), 날숨(Exhale), 유지(Hold) 단계별 타이머 및 직관적인 시각적 가이드 애니메이션
   - 세션 완수 후 피드백 수집 및 컨디션 변화 기록

4. **호흡 & 컨디션 히스토리 로그 (Log & Analytics)**
   - 일별/주별 호흡 운동 및 컨디션 측정 데이터 기록 관리 (`shared_preferences`)
   - 기록 상세 보기 및 트렌드 통계 화면 제공

5. **다크 모드 중심 프리미엄 UI/UX (Premium Dark Theme & Typography)**
   - 눈이 편안한 Dark Theme 베이스와 Mint/Coral 포인트 컬러 적용
   - Pretendard & GmarketSans 폰트 적용으로 뛰어난 가독성 제공

---

## 🛠 기술 스택 (Tech Stack)

| 구분 | 기술 / 라이브러리 |
| :--- | :--- |
| **Framework** | Flutter (Dart SDK `>=3.0.0 <4.0.0`) |
| **State & Storage** | SharedPreferences |
| **Hardware & Sensor** | Camera, Permission Handler, Heart BPM (PPG Sensor) |
| **UI & Styling** | Material 3, Google Fonts, Pretendard, GmarketSans, Responsive Utils |

---

## 📁 프로젝트 구조 (Directory Structure)

```text
lib/
├── main.dart                      # 앱 진입점 및 테마 설정
├── screens/                       # 주요 화면
│   ├── splash_screen.dart         # 스플래시 화면
│   ├── onboarding_screen.dart     # 온보딩 화면
│   ├── home_screen.dart           # 홈 대시보드
│   ├── condition_measurement_screen.dart # 심박수/컨디션 측정
│   ├── measurement_result_screen.dart    # 측정 결과
│   ├── recommended_breathing_screen.dart # 추천 호흡 루틴
│   ├── breathing_exercise_screen.dart    # 가이드 호흡 운동
│   ├── breathing_feedback_screen.dart    # 호흡 피드백
│   ├── breathing_completion_screen.dart  # 호흡 완료 요약
│   └── log_screen.dart            # 기록 및 분석
├── theme/                         # 컬러, 폰트, 스타일 정의
├── utils/                         # PPG 센서 서비스, 로직, 반응형 모듈
└── widgets/                       # 재사용 커스텀 위젯
```

---

## 🚀 시작하기 (Getting Started)

### 요구 사항 (Prerequisites)
- Flutter SDK `>= 3.0.0`
- Android Studio / VS Code
- 실기기 테스트 권장 (카메라 및 플래시 센서 사용 필요)

### 설치 및 실행 (Installation & Run)

```bash
# 1. 저장소 클론
git clone <repository-url>

# 2. 프로젝트 디렉터리로 이동
cd breath-care

# 3. 의존성 패키지 설치
flutter pub get

# 4. 앱 실행 (카메라 기능이 필요한 경우 실기기 연결 권장)
flutter run
```

---

## 📄 라이선스 (License)
This project is for internal/personal development.
