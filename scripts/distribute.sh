#!/usr/bin/env bash
#
# Build the release APK and push it to Firebase App Distribution testers.
# Testers get a phone notification to update — no more re-sending APK files.
#
# One-time setup (see docs/DISTRIBUTE.md):
#   1. Have `flutter` and `firebase` on your PATH.
#   2. Run `firebase login` once.
#   3. Create a tester group named "testers" in the Firebase console
#      (App Distribution → Testers & Groups) and add your friends' emails.
#
# Usage:
#   ./scripts/distribute.sh "What changed in this build"
#
set -euo pipefail

APP_ID="1:270036019497:android:200a917df4eddec78cef38"   # Helix Android app
GROUP="${DISTRIBUTE_GROUP:-testers}"
NOTES="${1:-New Helix test build}"

cd "$(dirname "$0")/.."

command -v flutter  >/dev/null 2>&1 || { echo "✗ flutter not on PATH.";  exit 1; }
command -v firebase >/dev/null 2>&1 || { echo "✗ firebase not on PATH (see docs/DISTRIBUTE.md)."; exit 1; }

echo "▶ Building release APK (prod flavor)…"
flutter build apk --release --dart-define-from-file=flavors/prod.json

echo "▶ Uploading to Firebase App Distribution → group '$GROUP'…"
firebase appdistribution:distribute \
  build/app/outputs/flutter-apk/app-release.apk \
  --app "$APP_ID" \
  --groups "$GROUP" \
  --release-notes "$NOTES"

echo "✔ Done — testers in '$GROUP' get a notification to update."
