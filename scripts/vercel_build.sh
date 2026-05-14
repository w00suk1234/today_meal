#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"
FLUTTER_DIR="${VERCEL_FLUTTER_DIR:-$HOME/flutter}"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
    echo "Installing Flutter $FLUTTER_VERSION for Vercel build..."
    rm -rf "$FLUTTER_DIR"
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
  export PATH="$FLUTTER_DIR/bin:$PATH"
fi

AI_BASE_URL="${AI_API_BASE_URL:-}"
if [ -z "$AI_BASE_URL" ] && [ -n "${VERCEL_URL:-}" ]; then
  AI_BASE_URL="https://${VERCEL_URL}"
fi

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=AI_API_BASE_URL="$AI_BASE_URL"
