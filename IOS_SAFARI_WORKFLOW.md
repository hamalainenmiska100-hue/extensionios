# iOS Safari Extension App Workflow

This repo contains `exttt.zip` (your existing browser extension). Use the script below to generate a native iOS app + Safari Web Extension container and a native message bridge.

## Prerequisites

- macOS
- Xcode 15+
- Apple Developer signing setup

## Generate the iOS project

```bash
./scripts/create_ios_safari_app.sh
```

Optional custom arguments:

```bash
./scripts/create_ios_safari_app.sh <zip_path> <app_name> <bundle_id_prefix> <out_dir>
```

Example:

```bash
./scripts/create_ios_safari_app.sh ./exttt.zip MySafariBridge com.yourcompany ./build-ios
```

## What the script does

1. Unzips `exttt.zip`.
2. Runs `xcrun safari-web-extension-converter` to create an iOS app + Safari extension project.
3. Replaces `ContentView.swift` with an instruction-only UI telling users to enable the extension in Safari settings.
4. Replaces `SafariWebExtensionHandler.swift` with a working native bridge handler for `browser.runtime.sendNativeMessage`.

## Build and run

1. Open the generated `.xcodeproj` in Xcode.
2. Set **Signing & Capabilities** for both app and extension targets.
3. Build and run on a real iPhone/iPad (or simulator for limited testing).
4. On device, enable extension:
   - **Settings → Apps → Safari → Extensions → [Your App] → ON**
   - Optional: Allow on all websites.


### Command-line simulator build (auto-detects scheme)

If `xcodebuild` fails with `does not contain a scheme named ...`, use the helper script below.
It lists the project schemes and automatically picks the first shared scheme:

```bash
./scripts/build_ios_sim.sh
```

Optional arguments:

```bash
./scripts/build_ios_sim.sh <path_to_xcodeproj> <configuration> <destination>
```

Example:

```bash
./scripts/build_ios_sim.sh build-ios/ExtttSafariBridge/ExtttSafariBridge.xcodeproj Debug "platform=iOS Simulator,name=iPhone 15"
```

## Bridge usage from extension JavaScript

Use:

```js
browser.runtime.sendNativeMessage("application.id", { type: "ping" })
```

The native handler responds with:

```json
{ "ok": true, "platform": "ios", "echo": { ...yourMessage } }
```
