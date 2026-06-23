# TodayMeal

- Demo: [https://today-meal-ai.vercel.app](https://today-meal-ai.vercel.app/)
- Repository: [https://github.com/w00suk1234/today_meal](https://github.com/w00suk1234/today_meal)

## 프로젝트 소개

TodayMeal은 사진으로 식단을 기록하고, 사용자가 확인한 음식 정보를 기준으로 칼로리와 탄단지를 계산하는 Flutter 식단 기록 앱입니다.

AI는 음식 후보를 제시하는 역할만 담당합니다. 최종 기록과 영양 계산은 사용자가 선택한 음식과 로컬 음식 DB를 기준으로 처리합니다.

| 홈 | 사진 기록 | 식단 기록 |
| --- | --- | --- |
| <img src="docs/screenshots/home.png" width="220" alt="홈 화면" /> | <img src="docs/screenshots/add-photo.png" width="220" alt="사진으로 식단 추가" /> | <img src="docs/screenshots/records.png" width="220" alt="식단 기록 화면" /> |
| 리포트 | 건강 정보 | 설정 |
| <img src="docs/screenshots/report.png" width="220" alt="리포트 화면" /> | <img src="docs/screenshots/health.png" width="220" alt="건강 정보 화면" /> | <img src="docs/screenshots/settings.png" width="220" alt="설정 화면" /> |

## 주요 기능

- 음식 사진 업로드 및 미리보기
- Mock/Remote AI 음식 후보 표시
- 사용자가 선택한 음식 기준 식단 기록 저장
- 로컬 음식 DB 기반 칼로리, 탄수화물, 단백질, 지방 계산
- 끼니별 기록, 날짜별 식단 기록 확인
- BMI, BMR, TDEE 계산
- 식단 기록 기반 규칙형 리포트 생성
- Supabase 연동을 위한 클라이언트와 schema 준비

## 기술 스택

- App: Flutter, Dart
- State/Data: Repository 패턴, shared_preferences, path_provider
- Image: image_picker, image
- Network/API: http, Vercel Serverless Functions
- Backend 준비: Supabase Flutter, Supabase schema
- Utilities: intl, crypto
- Lint/Test: flutter_lints, flutter_test

## 핵심 구현 포인트

- AI 분석 결과는 음식 후보 목록으로만 사용하고, 칼로리 확정값으로 사용하지 않습니다.
- Remote AI 설정이 없거나 사용할 수 없는 경우 MockVisionFoodService로 앱 흐름을 확인할 수 있습니다.
- `assets/data/food_db_kr_sample.json`의 음식 데이터를 기준으로 영양 정보를 계산합니다.
- `AppConfig`는 `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AI_API_BASE_URL`을 `--dart-define`으로 받습니다.
- `api/analyze-food.ts`와 `api/meal-coach.ts`는 클라이언트에 AI Provider Key를 노출하지 않기 위한 서버 API 구조입니다.

## 프로젝트 구조

```txt
today_meal/
├─ api/
│  ├─ analyze-food.ts
│  ├─ meal-coach.ts
│  └─ health.ts
├─ assets/
│  └─ data/food_db_kr_sample.json
├─ docs/
│  └─ screenshots/
├─ lib/
│  ├─ core/
│  ├─ data/
│  ├─ presentation/
│  ├─ services/
│  └─ app.dart
├─ supabase/
│  └─ schema.sql
├─ pubspec.yaml
└─ README.md
```

## 실행 방법

```bash
flutter pub get
flutter run
```

Chrome에서 AI API 주소와 함께 실행하는 예시는 아래와 같습니다.

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key \
  --dart-define=AI_API_BASE_URL=https://today-meal-ai.vercel.app
```

웹 빌드는 아래 명령으로 생성합니다.

```bash
flutter build web
```

환경변수 예시는 `.env.example`을 기준으로 확인합니다. `OPENAI_API_KEY` 같은 AI Provider Key는 Flutter 클라이언트 코드에 넣지 않고 서버 환경변수로만 설정합니다.

## 배포 주소 또는 데모 주소

- Web demo: [https://today-meal-ai.vercel.app](https://today-meal-ai.vercel.app)

## 개선 예정 사항

- Supabase 동기화 흐름을 실제 사용자 계정 기준으로 정리
- 음식 DB 확장 및 검색 정확도 개선
- AI 후보와 로컬 DB 음식 매칭 UX 개선
- 리포트 규칙과 건강 지표 안내 문구 보완
