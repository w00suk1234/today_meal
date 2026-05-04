Write-Host "오늘식단 AI Flutter Web 테스트를 시작합니다." -ForegroundColor Cyan

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
  Write-Host "flutter 명령어를 찾지 못했습니다." -ForegroundColor Red
  Write-Host "VSCode를 완전히 껐다 켠 뒤 다시 실행하거나, Flutter SDK의 bin 폴더가 PATH에 있는지 확인하세요."
  Write-Host "예: C:\dev\flutter\bin"
  exit 1
}

Write-Host "Flutter 위치: $($flutter.Source)" -ForegroundColor DarkGray

Write-Host "1/3 Flutter 상태 확인..." -ForegroundColor Cyan
flutter doctor
if ($LASTEXITCODE -ne 0) {
  Write-Host "flutter doctor에서 문제가 발견되었습니다. 위 메시지를 확인하세요." -ForegroundColor Yellow
}

Write-Host "2/3 패키지 설치 확인..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
  Write-Host "flutter pub get 실패. 네트워크 또는 pub.dev 접근 문제일 수 있습니다." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host "3/3 Chrome으로 실행..." -ForegroundColor Cyan
flutter run -d chrome --web-port=5173
