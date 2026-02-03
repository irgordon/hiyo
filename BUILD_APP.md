# **🚀 Building Hiyo for macOS — Complete Guide**

This guide walks you through building **Hiyo**, a local‑first macOS AI application, from source using **Xcode** and **Swift Package Manager**, and packaging it into a **signed, notarized DMG** for distribution.

It is written for **new macOS developers** and assumes no prior experience with code signing or Apple’s distribution pipeline.

---

# **1. Prerequisites**

| Requirement | Version | Notes |
|------------|---------|-------|
| **macOS** | 14.0+ | Required for MLX GPU support |
| **Xcode** | 15.0+ | Includes Swift 5.9+ |
| **Apple Developer Account** | Free or paid | Needed for signing & notarization |
| **Git** | Latest | For cloning the repo |
| **Homebrew** (optional) | Latest | For DMG tooling |

---

# **2. Clone the Repository**

If you are building from the official repo:

```bash
git clone https://github.com/hiyoai/hiyo.git
cd hiyo
```

If you are creating a fresh project structure manually, skip cloning and follow the directory setup in the next section.

---

# **3. Project Structure (Only if Creating From Scratch)**

If you cloned the repo, **you can skip this entire section**.

To create the full directory layout manually:

```bash
mkdir -p Sources/Hiyo/{Core,Models,Security,UI/{Welcome,Chat,Sidebar,Settings,Shared},Resources,Utils/Extensions}
mkdir -p Assets/AppIcon.appiconset
mkdir -p Tests/HiyoTests
mkdir -p Tests/HiyoUITests

touch Package.swift
touch README.md
touch LICENSE
```

---

# **4. Configure `Package.swift`**

Hiyo is built using **Swift Package Manager**.  
Place this in the project root:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hiyo",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Hiyo", targets: ["Hiyo"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.18.0"),
        .package(url: "https://github.com/huggingface/swift-transformers.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "Hiyo",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXRandom", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "Transformers", package: "swift-transformers")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "HiyoTests",
            dependencies: ["Hiyo"]
        )
    ]
)
```

---

# **5. Add Source Files**

Copy all Swift files into the appropriate folders under `Sources/Hiyo/`.

Quick verification:

```bash
find Sources -name "*.swift" | wc -l
```

You should see **40+ files**.

---

# **6. Open the Project in Xcode**

The recommended workflow is to open the package directly:

```bash
open Package.swift
```

Xcode will automatically generate a workspace for you.

---

# **7. Configure Xcode Build Settings**

## **7.1 Signing & Capabilities**

1. Select the **Hiyo** target.
2. Go to **Signing & Capabilities**.
3. Set:
   - **Team**: Your Apple ID
   - **Bundle Identifier**: `ai.hiyo.mac`
   - **Signing Certificate**: Development

## **7.2 Required Capabilities**

Add:

- **App Sandbox**
- **Hardened Runtime**

Recommended entitlements:

```xml
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
```

> **Note:**  
> Do *not* enable `network.server` unless your app truly needs to run a server.

## **7.3 Deployment & Build Settings**

- Deployment Target: **macOS 14.0**
- Swift Version: **5.9**
- Hardened Runtime: **Enabled**

---

# **8. Build & Test**

## **8.1 Command Line**

```bash
swift package resolve
swift build
swift build -c release
swift test
```

## **8.2 Xcode**

- **Cmd+B** — Build  
- **Cmd+R** — Run  
- **Cmd+U** — Run tests  

---

# **9. Archive for Distribution**

## **9.1 Using Xcode (Recommended)**

1. Product → **Archive**
2. Select the archive in Organizer
3. Click **Distribute App**
4. Choose **Copy App**
5. Save to `build/Hiyo.app`

## **9.2 Using Command Line**

```bash
xcodebuild -scheme Hiyo \
    -configuration Release \
    -archivePath build/Hiyo.xcarchive \
    archive
```

Export:

```bash
xcodebuild -exportArchive \
    -archivePath build/Hiyo.xcarchive \
    -exportOptionsPlist exportOptions.plist \
    -exportPath build/Export
```

---

# **10. Code Signing**

Verify signature:

```bash
codesign -dv --verbose=4 build/Export/Hiyo.app
spctl -a -vv build/Export/Hiyo.app
```

Manual signing (if needed):

```bash
codesign --deep --force --verify --verbose \
    --options runtime \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --entitlements Hiyo.entitlements \
    build/Export/Hiyo.app
```

---

# **11. Create a DMG Installer**

## **11.1 Using `create-dmg` (Easy)**

Install:

```bash
brew install create-dmg
```

Prepare staging:

```bash
mkdir -p build/dmg-staging
cp -R build/Export/Hiyo.app build/dmg-staging/
ln -s /Applications build/dmg-staging/Applications
```

Create DMG:

```bash
create-dmg \
    --volname "Hiyo Installer" \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Hiyo.app" 175 120 \
    --app-drop-link 425 120 \
    build/Hiyo-1.0.0.dmg \
    build/dmg-staging/
```

---

# **12. Notarize the DMG (Required for Distribution)**

Use **notarytool** (modern method):

```bash
xcrun notarytool submit build/Hiyo-1.0.0.dmg \
  --apple-id "your@apple.com" \
  --team-id YOUR_TEAM_ID \
  --password "@keychain:AC_PASSWORD" \
  --wait
```

Staple:

```bash
xcrun stapler staple build/Hiyo-1.0.0.dmg
```

Verify:

```bash
spctl -a -t open --context context:primary-signature -v build/Hiyo-1.0.0.dmg
```

---

# **13. Test on a Clean System**

1. Mount DMG  
2. Drag **Hiyo.app** to Applications  
3. Launch  
4. Verify:
   - No Gatekeeper warnings  
   - MLX loads models  
   - Chat works  
   - Settings persist  
   - Export functions work  

---

# **14. Final Output Structure**

```
build/
├── Hiyo.xcarchive/
├── Export/Hiyo.app
├── dmg-staging/
└── Hiyo-1.0.0.dmg
```

---

# **15. Optional: Automated Build Script**

Place in `build.sh`:

```bash
#!/bin/bash
set -e

APP_NAME="Hiyo"
VERSION="1.0.0"
BUILD_DIR="build"
TEAM_ID="YOUR_TEAM_ID"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

xcodebuild -scheme Hiyo -configuration Release \
    -archivePath $BUILD_DIR/Hiyo.xcarchive archive

xcodebuild -exportArchive \
    -archivePath $BUILD_DIR/Hiyo.xcarchive \
    -exportOptionsPlist exportOptions.plist \
    -exportPath $BUILD_DIR/Export

codesign --deep --force --verify --verbose \
    --options runtime \
    --sign "Developer ID Application: $TEAM_ID" \
    $BUILD_DIR/Export/Hiyo.app

mkdir -p $BUILD_DIR/dmg-staging
cp -R $BUILD_DIR/Export/Hiyo.app $BUILD_DIR/dmg-staging/
ln -s /Applications $BUILD_DIR/dmg-staging/Applications

create-dmg \
    --volname "Hiyo $VERSION" \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Hiyo.app" 175 190 \
    --app-drop-link 425 190 \
    "$BUILD_DIR/$APP_NAME-$VERSION.dmg" \
    "$BUILD_DIR/dmg-staging/"
```

---

# **🎉 You’re Done**

You now have:

- A fully built macOS app  
- A signed, notarized DMG  
