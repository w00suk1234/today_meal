$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$localFlutter = Join-Path $projectRoot ".tooling\flutter\bin\flutter.bat"
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"

if (Test-Path $localFlutter) {
  $flutter = $localFlutter
  $flutterRoot = Resolve-Path (Join-Path $projectRoot ".tooling\flutter")
  $env:GIT_CONFIG_COUNT = "1"
  $env:GIT_CONFIG_KEY_0 = "safe.directory"
  $env:GIT_CONFIG_VALUE_0 = $flutterRoot.Path
} else {
  $flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
  if (-not $flutterCommand) {
    Write-Host "Flutter SDK was not found." -ForegroundColor Red
    Write-Host "Install Flutter or run the Codex setup once to create .tooling\flutter."
    exit 1
  }
  $flutter = $flutterCommand.Source
}

if (Test-Path $chromePath) {
  $env:CHROME_EXECUTABLE = $chromePath
}

Write-Host "Starting Today Meal AI Flutter Web..." -ForegroundColor Cyan
Write-Host "Flutter: $flutter" -ForegroundColor DarkGray

Push-Location $projectRoot
try {
  Write-Host "1/2 Installing Flutter packages..." -ForegroundColor Cyan
  & $flutter pub get
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

  Write-Host "2/2 Running web server at http://127.0.0.1:5173" -ForegroundColor Cyan
  & $flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5173
  exit $LASTEXITCODE
} finally {
  Pop-Location
}
