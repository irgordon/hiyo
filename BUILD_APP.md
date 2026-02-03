## Building Hiyo for macOS

This guide covers building Hiyo from source using Xcode and creating a distributable DMG file.

---

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| macOS | 14.0+ | Sonoma required for MLX |
| Xcode | 15.0+ | With Swift 5.9+ |
| Apple Developer Account | Any | For code signing (free account works) |
| Git | Latest | For cloning dependencies |

---

## Step 1: Clone the Repository

```bash
# Clone the Hiyo repository
git clone https://github.com/hiyoai/hiyo.git
cd hiyo

# Or create directory structure manually
mkdir -p Hiyo && cd Hiyo
```

---

## Step 2: Set Up Project Structure

Create the complete directory structure:

```bash
# Create all directories
mkdir -p Sources/Hiyo/{Core/Models,Security,UI/{Welcome,Chat,Sidebar,Settings,Shared},Resources,Utils/Extensions}
mkdir -p Assets/AppIcon.appiconset
mkdir -p Tests/HiyoTests
mkdir -p Tests/HiyoUITests

# Create placeholder files
touch Package.swift
touch .gitignore
touch README.md
touch LICENSE
```

---

## Step 3: Configure Package.swift

Create `Package.swift` in the project root:

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

## Step 4: Populate Source Files

Copy all Swift source files into their respective directories:

```bash
# Copy all previously generated files to their locations
# Example structure:
# Sources/Hiyo/HiyoApp.swift
# Sources/Hiyo/ContentView.swift
# Sources/Hiyo/HiyoState.swift
# Sources/Hiyo/Core/HiyoStore.swift
# ... etc
```

**Quick verification command:**

```bash
# Count Swift files
find Sources -name "*.swift" | wc -l
# Should show: 40+ files
```

---

## Step 5: Create Xcode Project

Since we're using Swift Package Manager, generate the Xcode project:

```bash
# Generate Xcode project from Package.swift
swift package generate-xcodeproj

# Or open directly in Xcode (recommended)
open Package.swift
```

**Alternative: Manual Xcode Project Creation**

1. Open Xcode
2. File → New → Project
3. Select "App" under macOS
4. Configure:
   - **Product Name**: Hiyo
   - **Team**: Your Apple ID
   - **Organization Identifier**: ai.hiyo
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: SwiftData

5. Replace generated files with Hiyo source files

---

## Step 6: Configure Build Settings

### 6.1 Signing & Capabilities

1. Select `Hiyo` project in navigator
2. Select `Hiyo` target
3. Go to **Signing & Capabilities**
4. Set:
   - **Team**: Your Apple ID
   - **Bundle Identifier**: `ai.hiyo.mac`
   - **Signing Certificate**: Development

### 6.2 Add Capabilities

Click **+ Capability** and add:

- ✅ App Sandbox
- ✅ Hardened Runtime

**Entitlements** (auto-generated, verify contents):

```xml
<!-- Hiyo.entitlements -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
</dict>
</plist>
```

### 6.3 Build Configuration

1. Select project → **Info** tab
2. Set **Deployment Target**: macOS 14.0
3. Go to **Build Settings**:
   - `SWIFT_VERSION`: 5.9
   - `MACOSX_DEPLOYMENT_TARGET`: 14.0
   - `ENABLE_HARDENED_RUNTIME`: YES
   - `CODE_SIGN_INJECT_BASE_ENTITLEMENTS`: YES

---

## Step 7: Build for Testing

### 7.1 Command Line Build

```bash
# Resolve dependencies
swift package resolve

# Build debug version
swift build

# Build release version
swift build -c release

# Run tests
swift test
```

### 7.2 Xcode Build

```bash
# Open in Xcode
open Hiyo.xcodeproj
# or
open Package.swift
```

In Xcode:
1. Select **Product** → **Scheme** → **Hiyo**
2. Select **My Mac** as destination
3. Press **Cmd+B** to build
4. Press **Cmd+R** to run

---

## Step 8: Create Archive for Distribution

### 8.1 Using Xcode

1. Select **Product** → **Archive**
2. Wait for build completion
3. Organizer window opens automatically
4. Select the archive → **Distribute App**
5. Choose **Copy App**
6. Save to `build/Hiyo.app`

### 8.2 Using Command Line

```bash
# Clean build
rm -rf .build

# Create release archive
xcodebuild -project Hiyo.xcodeproj \
    -scheme Hiyo \
    -configuration Release \
    -archivePath build/Hiyo.xcarchive \
    archive

# Export app
xcodebuild -exportArchive \
    -archivePath build/Hiyo.xcarchive \
    -exportOptionsPlist exportOptions.plist \
    -exportPath build/Export
```

**Create exportOptions.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

---

## Step 9: Code Signing (Required for Distribution)

### 9.1 Verify Signing

```bash
# Check app signature
codesign -dv --verbose=4 build/Hiyo.app

# Verify Gatekeeper acceptance
spctl -a -vv build/Hiyo.app
```

### 9.2 Manual Signing (if needed)

```bash
# Sign with Developer ID
codesign --force --options runtime \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    --entitlements Hiyo.entitlements \
    build/Hiyo.app

# Deep sign
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (TEAM_ID)" \
    build/Hiyo.app
```

---

## Step 10: Create DMG Distribution

### 10.1 Prepare DMG Contents

```bash
# Create staging directory
mkdir -p build/dmg-staging
cp -R build/Hiyo.app build/dmg-staging/

# Create Applications shortcut
ln -s /Applications build/dmg-staging/Applications

# Add README and license (optional)
cp README.md build/dmg-staging/
cp LICENSE build/dmg-staging/
```

### 10.2 Create DMG using create-dmg

```bash
# Install create-dmg if not present
brew install create-dmg

# Create the DMG
create-dmg \
    --volname "Hiyo Installer" \
    --volicon "Assets/AppIcon.icns" \
    --background "Assets/dmg-background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Hiyo.app" 175 120 \
    --icon "Applications" 425 120 \
    --hide-extension "Hiyo.app" \
    --app-drop-link 425 120 \
    --no-internet-enable \
    --format UDZO \
    "build/Hiyo-1.0.0.dmg" \
    "build/dmg-staging/"
```

### 10.3 Alternative: Manual DMG Creation

```bash
# Create empty DMG
hdiutil create -size 100m -fs HFS+J -volname "Hiyo" -o build/Hiyo-temp.dmg

# Mount it
hdiutil attach build/Hiyo-temp.dmg -mountpoint /Volumes/Hiyo

# Copy files
cp -R build/Hiyo.app /Volumes/Hiyo/
ln -s /Applications /Volumes/Hiyo/Applications

# Set background (optional)
mkdir -p /Volumes/Hiyo/.background
cp Assets/dmg-background.png /Volumes/Hiyo/.background/

# Eject
hdiutil detach /Volumes/Hiyo

# Compress
hdiutil convert build/Hiyo-temp.dmg -format UDZO -o build/Hiyo-1.0.0.dmg

# Clean up
rm build/Hiyo-temp.dmg
```

### 10.4 Notarize DMG (Apple Developer Required)

```bash
# Submit for notarization
xcrun altool --notarize-app \
    --primary-bundle-id "ai.hiyo.mac" \
    --username "your@email.com" \
    --password "@keychain:AC_PASSWORD" \
    --file build/Hiyo-1.0.0.dmg

# Staple ticket after approval
xcrun stapler staple build/Hiyo-1.0.0.dmg

# Verify
xcrun stapler validate build/Hiyo-1.0.0.dmg
spctl -a -t open --context context:primary-signature -v build/Hiyo-1.0.0.dmg
```

---

## Step 11: Verify Distribution Build

### 11.1 Test on Clean System

```bash
# Mount DMG
hdiutil attach build/Hiyo-1.0.0.dmg

# Copy to Applications
cp -R /Volumes/Hiyo/Hiyo.app /Applications/

# Launch and test
open /Applications/Hiyo.app

# Check for issues
Console.app → Search "Hiyo"
```

### 11.2 Final Verification Checklist

- [ ] App launches without crashes
- [ ] MLX models load correctly
- [ ] Chat functionality works
- [ ] Settings save persistently
- [ ] Export/Import functions work
- [ ] No Gatekeeper warnings (if notarized)
- [ ] App icon displays correctly
- [ ] Version number correct in About

---

## Build Scripts

### Automated Build Script

Save as `build.sh`:

```bash
#!/bin/bash

set -e

APP_NAME="Hiyo"
VERSION="1.0.0"
BUILD_DIR="build"
TEAM_ID="YOUR_TEAM_ID"  # Replace with your Team ID

echo "🏗️  Building Hiyo $VERSION..."

# Clean
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Build
echo "📦 Creating archive..."
xcodebuild -project Hiyo.xcodeproj \
    -scheme Hiyo \
    -configuration Release \
    -archivePath $BUILD_DIR/Hiyo.xcarchive \
    archive

# Export
echo "📤 Exporting app..."
cat > $BUILD_DIR/exportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>$TEAM_ID</string>
</dict>
</plist>
EOF

xcodebuild -exportArchive \
    -archivePath $BUILD_DIR/Hiyo.xcarchive \
    -exportOptionsPlist $BUILD_DIR/exportOptions.plist \
    -exportPath $BUILD_DIR/Export

# Sign
echo "✍️  Signing..."
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application:" \
    $BUILD_DIR/Export/Hiyo.app

# Create DMG
echo "💿 Creating DMG..."
mkdir -p $BUILD_DIR/dmg-staging
cp -R $BUILD_DIR/Export/Hiyo.app $BUILD_DIR/dmg-staging/
ln -s /Applications $BUILD_DIR/dmg-staging/Applications

create-dmg \
    --volname "Hiyo $VERSION" \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Hiyo.app" 175 190 \
    --hide-extension "Hiyo.app" \
    --app-drop-link 425 190 \
    "$BUILD_DIR/$APP_NAME-$VERSION.dmg" \
    "$BUILD_DIR/dmg-staging/"

echo "✅ Build complete: $BUILD_DIR/$APP_NAME-$VERSION.dmg"
```

Make executable: `chmod +x build.sh`

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `MLX not found` | Run `swift package resolve` |
| Signing errors | Check Apple Developer account status |
| Sandbox violations | Review entitlements file |
| Gatekeeper blocked | Right-click → Open, or notarize |
| DMG creation fails | Install `create-dmg` via Homebrew |
| Memory errors | Reduce MLX cache limit in code |

---

## Output Files

After successful build:

```
build/
├── Hiyo.xcarchive/          # Xcode archive
├── Export/
│   └── Hiyo.app/            # Signed app bundle
├── dmg-staging/             # Temporary DMG contents
└── Hiyo-1.0.0.dmg           # Final distribution DMG
```

---

## Distribution

Upload `Hiyo-1.0.0.dmg` to:
- GitHub Releases
- Your website
- Mac App Store (requires additional signing)

---

**Build time**: ~5-10 minutes (depending on machine)
**Final app size**: ~50-100 MB (without models)
**DMG size**: ~30-60 MB (compressed)
