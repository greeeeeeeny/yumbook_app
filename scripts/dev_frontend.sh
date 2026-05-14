#!/usr/bin/env bash
# Run the Flutter app for web development.
set -euo pipefail
cd "$(dirname "$0")/../frontend"
export PATH="$PWD/../.flutter-sdk/flutter/bin:$PATH"
flutter pub get
exec flutter run -d chrome
