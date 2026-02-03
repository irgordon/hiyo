# **🚀 Hiyo Quick Start Guide**

Welcome! This guide helps you build and run **Hiyo**, a local‑first macOS AI app, in just a few minutes.

If you want deeper instructions (DMG creation, notarization, entitlements, etc.), see the full `BUILD_APP.md` guide.  
This document is strictly the **fast path**.

---

# **1. Requirements**

| Tool | Version |
|------|---------|
| macOS | **14.0+** |
| Xcode | **15.0+** |
| Swift | **5.9+** |
| Apple Developer Account | Free or paid |
| Git | Latest |

Hiyo uses **MLX**, so macOS Sonoma or later is required.

---

# **2. Clone the Repository**

```bash
git clone https://github.com/hiyoai/hiyo.git
cd hiyo
```

---

# **3. Open the Project in Xcode**

Hiyo is built with **Swift Package Manager**.

```bash
open Package.swift
```

Xcode will automatically generate a workspace.

---

# **4. Configure Signing (One‑Time Setup)**

1. In Xcode, select the **Hiyo** target.
2. Go to **Signing & Capabilities**.
3. Set:
   - **Team** → your Apple ID
   - **Bundle Identifier** → `ai.hiyo.mac`
4. Ensure these capabilities are enabled:
   - **App Sandbox**
   - **Hardened Runtime**

That’s it — no extra entitlements needed for local‑only operation.

---

# **5. Build & Run**

In Xcode:

- **Cmd+B** — Build  
- **Cmd+R** — Run  

Or from the command line:

```bash
swift build
```

Hiyo should launch immediately and load the default MLX model.

---

# **6. Optional: Build a Release App**

```bash
swift build -c release
```

The compiled binary will be in:

```
.build/release/Hiyo
```

---

# **7. Optional: Create a DMG Installer**

If you want a distributable DMG:

```bash
brew install create-dmg
```

Then:

```bash
mkdir -p build/dmg-staging
cp -R build/Export/Hiyo.app build/dmg-staging/
ln -s /Applications build/dmg-staging/Applications

create-dmg \
  --volname "Hiyo Installer" \
  build/Hiyo.dmg \
  build/dmg-staging/
```

For notarization, see the full build guide.

---

# **8. Troubleshooting**

| Issue | Fix |
|-------|-----|
| MLX not found | `swift package resolve` |
| Signing errors | Ensure your Apple ID is selected in Xcode |
| App won’t open | Right‑click → Open (Gatekeeper) |
| Model won’t load | Ensure macOS 14+ and Apple Silicon |

---

# **🎉 You’re Ready**

You now have Hiyo running locally on macOS with MLX acceleration.  
For advanced topics (security, entitlements, DMG signing, notarization), check the full documentation.
