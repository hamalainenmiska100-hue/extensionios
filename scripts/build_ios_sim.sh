#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${1:-build-ios/ExtttSafariBridge/ExtttSafariBridge.xcodeproj}"
CONFIGURATION="${2:-Debug}"
DESTINATION="${3:-platform=iOS Simulator,name=iPhone 15}"

if [[ ! -d "$PROJECT_PATH" ]]; then
  echo "❌ Xcode project not found: $PROJECT_PATH"
  echo "Run ./scripts/create_ios_safari_app.sh first (or pass a custom .xcodeproj path)."
  exit 1
fi

# Pick a shared scheme from the project automatically.
SCHEME="$((xcodebuild -list -project "$PROJECT_PATH" 2>/dev/null || true) | awk '
  /^Schemes:/ { in_schemes=1; next }
  in_schemes && NF { gsub(/^[[:space:]]+/, ""); print; exit }
')"

if [[ -z "$SCHEME" ]]; then
  echo "❌ No shared schemes found in project: $PROJECT_PATH"
  echo "Open the project in Xcode and ensure at least one scheme is shared."
  exit 1
fi

echo "ℹ️ Using scheme: $SCHEME"

echo "ℹ️ Building project: $PROJECT_PATH"
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -sdk iphonesimulator \
  -destination "$DESTINATION" \
  CODE_SIGNING_ALLOWED=NO \
  clean build
