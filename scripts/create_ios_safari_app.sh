#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ZIP_PATH="${1:-$ROOT_DIR/exttt.zip}"
APP_NAME="${2:-ExtttSafariBridge}"
BUNDLE_ID_PREFIX="${3:-com.example}"
OUT_DIR="${4:-$ROOT_DIR/build-ios}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ This script must run on macOS with Xcode installed."
  exit 1
fi

if [[ ! -f "$ZIP_PATH" ]]; then
  echo "❌ Zip not found: $ZIP_PATH"
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "❌ xcrun not found. Install Xcode + command line tools."
  exit 1
fi

WORK_DIR="$OUT_DIR/work"
EXT_DIR="$WORK_DIR/extension-src"
PROJECT_DIR="$OUT_DIR/$APP_NAME"

rm -rf "$WORK_DIR"
mkdir -p "$EXT_DIR" "$OUT_DIR"
unzip -q "$ZIP_PATH" -d "$EXT_DIR"

# Convert the Chromium extension into a Safari Web Extension app container.
# --force: overwrite if project already exists
# --copy-resources: keep extension assets in app project
xcrun safari-web-extension-converter \
  "$EXT_DIR" \
  --project-location "$OUT_DIR" \
  --app-name "$APP_NAME" \
  --bundle-identifier "$BUNDLE_ID_PREFIX.$APP_NAME" \
  --copy-resources \
  --swift \
  --force

APP_SWIFT="$(find "$PROJECT_DIR" -name '*App.swift' | head -n 1 || true)"
if [[ -n "$APP_SWIFT" ]]; then
  APP_GROUP_DIR="$(dirname "$APP_SWIFT")"
  CONTENT_SWIFT="$APP_GROUP_DIR/ContentView.swift"

  cat > "$CONTENT_SWIFT" <<'SWIFT'
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Safari Extension Installed")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Enable it here:")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("1. Open Settings")
                Text("2. Tap Apps → Safari → Extensions")
                Text("3. Turn on this extension")
                Text("4. (Optional) Allow on All Websites")
            }
            .font(.body)

            Text("After enabling, open Safari and use the extension from the puzzle icon.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 8)

            Spacer()
        }
        .padding(24)
    }
}
SWIFT
else
  echo "⚠️ App.swift not found in generated project; skipping ContentView.swift customization."
fi

# Add a basic native bridge endpoint available to extension scripts as browser.runtime.sendNativeMessage.
HANDLER_SWIFT="$(find "$PROJECT_DIR" -name 'SafariWebExtensionHandler.swift' | head -n 1 || true)"
if [[ -n "$HANDLER_SWIFT" ]]; then
cat > "$HANDLER_SWIFT" <<'SWIFT'
import SafariServices
import os.log

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        let item = context.inputItems.first as? NSExtensionItem
        let userInfo = item?.userInfo?[SFExtensionMessageKey] as? [String: Any]

        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@", userInfo ?? [:])

        let response = NSExtensionItem()
        response.userInfo = [
            SFExtensionMessageKey: [
                "ok": true,
                "platform": "ios",
                "echo": userInfo ?? [:]
            ]
        ]

        context.completeRequest(returningItems: [response], completionHandler: nil)
    }
}
SWIFT
fi

cat <<MSG
✅ Project created at: $PROJECT_DIR

Next steps:
1) Open "$PROJECT_DIR/$APP_NAME.xcodeproj" in Xcode.
2) Set Signing & Capabilities for app + extension targets.
3) Build and run on iPhone/iPad.
4) In iOS Settings: Apps → Safari → Extensions → enable $APP_NAME.
MSG
