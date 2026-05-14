# 오늘의 식단

> 사진 기반 AI 음식 후보, 식단 기록, 개인 건강 지표, 식사 시간 피드백을 결합한 Flutter 포트폴리오 앱

오늘의 식단은 음식 사진을 업로드하고, AI 후보 추정 흐름을 통해 식단을 기록하는 모바일/Web 앱 MVP입니다.  
기본 실행은 `MockVisionFoodService`로 AI 분석 UX를 시연하고, `AI_API_BASE_URL`이 설정되면 Vercel API Route를 통해 실제 Vision AI 음식 후보 분석을 호출합니다. 칼로리와 탄단지는 AI가 확정하지 않으며, 로컬 음식 DB와 사용자가 확인한 섭취량을 기준으로 앱 내부에서 계산합니다.

## 주요 기능

- 음식 사진 업로드 및 카메라 촬영
- Mock/Remote AI 기반 음식 후보 표시
- 음식 후보 체크/해제 및 섭취량 조정
- 로컬 음식 DB 기반 칼로리/탄수화물/단백질/지방 계산
- 오늘 식단 대시보드
- 날짜별 식단 기록 및 삭제
- 규칙 기반 식단 리포트
- 개인 건강 프로필 관리
- BMI, BMR, TDEE, 목표 칼로리 계산
- 식사 시작/종료 시간 기록
- 식사 시간 패턴 피드백
- Supabase 연동 준비 및 RLS SQL 포함
- Flutter Web 데모 및 Android APK 빌드 구조

## 화면 미리보기

| 홈 | 추가 | 기록 |
| --- | --- | --- |
| <img src="docs/screenshots/home.png" width="280" alt="홈 화면"> | <img src="docs/screenshots/add-photo.png" width="280" alt="식단 추가 화면"> | <img src="docs/screenshots/records.png" width="280" alt="식단 기록 화면"> |

| 리포트 | 몸상태 | 설정 |
| --- | --- | --- |
| <img src="docs/screenshots/report.png" width="280" alt="오늘 리포트 화면"> | <img src="docs/screenshots/health.png" width="280" alt="내 몸 상태 화면"> | <img src="docs/screenshots/settings.png" width="280" alt="설정 화면"> |

## 기술 스택

- Flutter
- Dart
- Material 3
- shared_preferences
- image_picker
- supabase_flutter
- Supabase PostgreSQL, RLS 설계
- Vercel 배포 구조

## 앱 구조

```text
lib/
  core/
    constants/
    utils/
      nutrition_calculator.dart
      health_calculator.dart
      meal_timing_analyzer.dart
      report_generator.dart
  data/
    local/
    remote/
    models/
    repositories/
  presentation/
    screens/
      home/
      add_meal/
      records/
      report/
      health/
      settings/
    widgets/
  services/
    vision_food_service.dart

assets/
  data/food_db_kr_sample.json

supabase/
  schema.sql
```

## 화면 구성

| 화면 | 설명 |
| --- | --- |
| 홈 | 오늘 섭취 칼로리, 목표 대비 진행률, 탄단지, BMI/BMR 요약, 식사 시간 피드백 |
| 추가 | 사진 업로드, Mock AI 음식 후보, 음식 검색, 섭취량 선택, 식사 시간 입력 |
| 기록 | 날짜별 식단 기록, 식사 유형별 그룹, 기록 삭제 |
| 리포트 | 칼로리, 탄단지, 식사 시간, BMI, 목표 칼로리 기반 규칙 리포트 |
| 몸상태 | 닉네임, 성별, 생년월일, 키/몸무게, 활동량, 목표, 취침 시간 관리 |
| 설정 | 기본 목표 칼로리 및 사용자 설정 |

## AI/VLM 설계

기본 실행은 실제 OpenAI, Gemini, Claude API를 호출하지 않고 Mock 후보를 반환합니다. `AI_API_BASE_URL`을 넣어 빌드하면 Flutter Web 앱이 같은 Vercel 프로젝트의 `/api/analyze-food` 서버 API를 호출합니다.

```text
기본 데모 구조
Flutter App
→ MockVisionFoodService
→ 데모 음식 후보 반환
→ 로컬 FoodItem DB 매칭
→ 사용자가 섭취량 확인
→ 앱 내부 계산
```

```text
원격 Vision AI 구조
Flutter App
→ RemoteVisionFoodService
→ Vercel API Route (/api/analyze-food)
→ OpenAI Vision model
→ JSON 응답
→ Flutter App 표시
```

실제 연결 수정 위치:

```text
lib/services/vision_food_service.dart
```

## 건강 계산 공식

BMI:

```text
weightKg / (heightMeter * heightMeter)
```

BMR, Mifflin-St Jeor:

```text
male   = 10 * weightKg + 6.25 * heightCm - 5 * age + 5
female = 10 * weightKg + 6.25 * heightCm - 5 * age - 161
```

TDEE:

```text
BMR * activityFactor
```

목표 칼로리:

```text
loss     = TDEE - 400
maintain = TDEE
gain     = TDEE + 300
```

모든 결과는 건강 진단이나 처방이 아닌 식단 기록 참고용 추정 결과입니다.

## Supabase 설정

Supabase SQL editor에서 아래 파일을 실행합니다.

```text
supabase/schema.sql
```

포함된 테이블:

- profiles
- weight_logs
- meal_logs
- meal_items
- daily_summaries
- ai_analysis_logs

모든 개인 데이터 테이블은 RLS를 전제로 설계되어 있으며, `user_id = auth.uid()`인 데이터만 접근하도록 정책을 포함했습니다.

Flutter 실행 시 Supabase URL과 anon key는 코드에 하드코딩하지 않고 `--dart-define`으로 전달합니다.

```powershell
flutter run -d chrome `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-public-anon-key `
  --dart-define=AI_API_BASE_URL=https://your-ai-server.example.com
```

서비스 role key, OpenAI/Gemini/Claude API key는 Flutter 앱에 넣지 않습니다.

## AI 사진 분석 연동 원칙

- Flutter 클라이언트에는 OpenAI, Gemini, Claude 등 유료 AI Provider API Key를 절대 넣지 않습니다.
- Flutter 앱은 `AI_API_BASE_URL`로 설정한 서버에 압축된 음식 이미지만 전달합니다.
- 서버가 OpenAI/Gemini/Claude 등 VLM API를 호출하고, 앱에는 음식 후보와 신뢰도만 반환합니다.
- AI 결과는 최종 판단이 아니라 후보입니다. 칼로리와 탄단지는 AI가 확정하지 않고 로컬 음식 DB와 사용자가 확인한 섭취량 기준으로 계산합니다.
- 서버 저장 시 `image_url`에는 Supabase Storage URL 또는 외부 이미지 URL만 저장하고, `data:image/...` base64 문자열은 저장하지 않습니다.

## 실제 Vision AI 연동 방법

Flutter 앱은 `POST /api/analyze-food` 서버 API에 음식 이미지를 전송하고, 서버 API만 AI Provider API Key를 사용합니다. OpenAI/Gemini/Claude 같은 유료 Provider Key는 Flutter Web/mobile 코드나 `--dart-define`에 넣지 않습니다.

로컬 서버 환경변수 예시:

```powershell
$env:AI_PROVIDER="openai"
$env:AI_MODEL="gpt-4o-mini"
$env:OPENAI_API_KEY="your-openai-api-key"
```

`AI_MODEL`은 교체 가능합니다. 비워두면 서버 API는 저비용 vision 입력이 가능한 기본 모델로 `gpt-4o-mini`를 사용합니다.

Flutter 로컬 실행 예시:

```powershell
flutter run -d chrome `
  --dart-define=AI_API_BASE_URL=http://localhost:3000
```

Vercel 배포 시 Project Settings > Environment Variables에 아래 값을 등록합니다.

```text
AI_PROVIDER=openai
AI_MODEL=gpt-4o-mini
OPENAI_API_KEY=your-openai-api-key
```

배포된 앱에서 원격 분석을 쓰려면 Flutter 빌드에도 서버 주소를 전달합니다.

```powershell
flutter build web --release `
  --dart-define=AI_API_BASE_URL=https://your-vercel-app.vercel.app
```

AI 분석은 음식 후보, 신뢰도, 설명, 예상 섭취량, 로컬 DB 매칭 후보만 반환합니다. 칼로리와 탄수화물/단백질/지방은 AI가 만들지 않고, 기존 로컬 음식 DB와 사용자가 확인한 섭취량 기준으로 계산합니다.

비용 방어 전략:

- 사용자가 `AI 음식 분석 시작` 버튼을 눌렀을 때만 분석 요청
- Flutter에서 이미지를 리사이즈/압축한 뒤 전송
- 서버 응답 후보 최대 5개로 제한
- 서버에서 과도하게 큰 이미지 요청 거부
- TODO: 같은 이미지 반복 분석 캐시
- TODO: 사용자별 하루 분석 횟수 제한

## 실행 방법

패키지 설치:

```powershell
flutter pub get
```

Chrome Web 실행:

```powershell
flutter run -d chrome
```

Windows 빠른 실행:

```powershell
.\run_web.bat
```

## Android APK 빌드 및 실기기 테스트

Android 앱도 Flutter 클라이언트에는 `AI_API_BASE_URL`만 포함하고, 실제 `OPENAI_API_KEY`는 Vercel Environment Variables에만 저장합니다. APK는 Vercel API Route(`/api/analyze-food`)를 호출해 음식 후보 분석 결과를 받습니다.

필요 환경:

- Android Studio 또는 Android SDK Command-line Tools
- Android SDK Platform / Build Tools
- `adb`가 포함된 Platform Tools
- Android SDK가 기본 위치가 아니라면 `flutter config --android-sdk <Android SDK 경로>`로 경로 지정

포트폴리오/실기기 테스트용 release APK 빌드:

```powershell
flutter build apk --release `
  --dart-define=AI_API_BASE_URL=https://your-vercel-app.vercel.app
```

Vercel 서버 없이 Mock 분석만 테스트하려면 `AI_API_BASE_URL`을 빼고 빌드합니다.

```powershell
flutter build apk --release
```

APK 결과물:

```text
build/app/outputs/flutter-apk/app-release.apk
```

실기기 설치 테스트:

```powershell
adb devices
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Google Play 업로드용 AAB 빌드가 필요한 경우:

```powershell
flutter build appbundle --release `
  --dart-define=AI_API_BASE_URL=https://your-vercel-app.vercel.app
```

AAB 결과물:

```text
build/app/outputs/bundle/release/app-release.aab
```

Web 배포와 Android 앱의 차이:

- Flutter Web은 Vercel에 정적 파일(`build/web`)로 배포되고, 같은 Vercel 프로젝트의 `/api/analyze-food`를 호출합니다.
- Android APK는 기기에 설치되는 앱이며, Vercel에는 올라가지 않습니다.
- Android APK도 동일하게 `AI_API_BASE_URL`의 Vercel API 서버를 호출합니다.
- `OPENAI_API_KEY`는 Android 코드, APK, `--dart-define`에 넣지 않습니다.

주의사항:

- APK는 포트폴리오/테스트용 빌드입니다.
- Google Play 정식 출시는 별도 서명 키 관리, 정책 검토, 개인정보처리방침, 데이터 안전 섹션 준비가 필요합니다.
- 건강/다이어트 앱이므로 의료 조언이나 진단처럼 보이는 문구는 피해야 합니다.
- AI 분석은 참고용이며 최종 식단 기록과 섭취량은 사용자가 확인해야 합니다.

## Web 빌드 및 Vercel 배포

Flutter Web은 정적 파일로 `build/web`에 빌드되고, `api/analyze-food.ts`는 Vercel Serverless Function으로 함께 배포됩니다. API Route까지 같이 올라가야 하므로 `build/web` 폴더 안에서 배포하지 말고 반드시 프로젝트 루트에서 배포합니다.

로컬 Web 빌드:

```powershell
flutter build web --release
```

원격 AI 분석 서버 주소를 빌드에 넣는 경우:

```powershell
flutter build web --release `
  --dart-define=AI_API_BASE_URL=https://your-vercel-app.vercel.app
```

### Vercel 프로젝트 설정

`vercel.json`은 아래처럼 Flutter Web 정적 출력과 API Route를 함께 처리합니다.

```json
{
  "buildCommand": "bash scripts/vercel_build.sh",
  "outputDirectory": "build/web",
  "installCommand": "echo \"Flutter dependencies are installed during the Vercel build step.\"",
  "rewrites": [
    {"source": "/:path((?!api/).*)", "destination": "/index.html"}
  ]
}
```

- `outputDirectory`는 Flutter Web 결과물인 `build/web`입니다.
- `api/analyze-food.ts`는 프로젝트 루트의 `api/` 폴더에 있어 Vercel Serverless Function으로 배포됩니다.
- SPA 라우팅용 rewrite는 `/api/*`를 제외하므로 `/api/analyze-food` 요청은 Flutter `index.html`로 가지 않습니다.
- Vercel 빌드 환경에는 Flutter SDK가 없을 수 있어 `scripts/vercel_build.sh`가 Flutter를 설치한 뒤 `flutter build web --release`를 실행합니다.
- 빌드 스크립트는 `AI_API_BASE_URL`이 있으면 그대로 쓰고, 없으면 Vercel의 `VERCEL_URL`을 이용해 배포 URL을 자동 주입합니다.

Vercel Dashboard > Project Settings > Environment Variables에 서버용 값을 등록합니다.

```text
OPENAI_API_KEY=실제 OpenAI API Key
AI_PROVIDER=openai
AI_MODEL=gpt-4o-mini
```

Flutter 클라이언트에 들어가는 값은 공개 서버 주소뿐입니다. Production URL이 확정된 뒤 명시적으로 고정하고 싶다면 Vercel Environment Variables에 아래 값을 추가하고 재배포합니다.

```text
AI_API_BASE_URL=https://your-vercel-app.vercel.app
```

Vercel CLI 배포는 프로젝트 루트에서 실행합니다.

```powershell
npx vercel --prod
```

아직 Vercel 프로젝트가 없다면 둘 중 하나로 만듭니다.

1. Vercel Dashboard에서 Add New Project를 누르고 GitHub의 `w00suk1234/today_meal` 저장소를 Import합니다.
2. 또는 프로젝트 루트에서 `npx vercel`을 실행해 CLI 안내에 따라 새 프로젝트로 link/deploy합니다.

프로젝트를 만들 때 Root Directory는 저장소 루트로 두어야 합니다. `build/web`을 루트로 잡으면 `api/analyze-food.ts`가 배포되지 않습니다.

### 배포 후 smoke test

먼저 잘못된 요청이 JSON 에러로 돌아오는지 확인합니다. 이 테스트는 OpenAI 비용을 쓰지 않습니다.

```powershell
Invoke-RestMethod `
  -Method Post `
  -Uri "https://your-vercel-app.vercel.app/api/analyze-food" `
  -ContentType "application/json" `
  -Body "{}"
```

예상 응답:

```json
{
  "error": {
    "code": "IMAGE_REQUIRED",
    "message": "imageBase64가 필요합니다."
  }
}
```

실제 Vision AI 호출 테스트는 작은 음식 사진으로 진행합니다.

```powershell
$imageBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("sample-food.jpg"))
$body = @{
  imageBase64 = $imageBase64
  mimeType = "image/jpeg"
  availableFoods = @(
    @{ id = "brown_rice"; name = "잡곡밥"; category = "밥" },
    @{ id = "grilled_mackerel"; name = "고등어구이"; category = "생선" }
  )
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
  -Method Post `
  -Uri "https://your-vercel-app.vercel.app/api/analyze-food" `
  -ContentType "application/json" `
  -Body $body
```

## 프로젝트 포인트

- 단순 CRUD 앱이 아니라 식단 기록, 건강 지표, 생활 패턴 피드백을 하나의 흐름으로 연결
- Mock 데모와 서버 경유 Vision AI 분석을 모두 지원하는 계층 구조
- Flutter 클라이언트에 유료 AI Provider API Key를 넣지 않는 안전한 서버 경유 구조
- Web, Android, iOS 구조를 모두 유지
- 의료/처방 앱이 아닌 참고용 건강 관리 앱으로 안전한 문구와 책임 범위 명시
