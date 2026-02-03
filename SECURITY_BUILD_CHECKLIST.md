# **🔐 Security‑Hardened Build Configuration Checklist (macOS)**

This checklist ensures the Hiyo build pipeline follows **Apple’s security, privacy, and distribution standards**.  
Every release build must pass **all** items.

---

# **1. Code Signing & Identity**

### **Signing Identity**
- [ ] The app is signed with a **Developer ID Application** certificate for distribution.
- [ ] The signing identity matches the expected **TEAM_ID**.
- [ ] No ad‑hoc signing is used in release builds.
- [ ] No expired or revoked certificates are referenced.

### **Verification**
- [ ] `codesign -dv --verbose=4 Hiyo.app` shows:
  - Hardened Runtime: **enabled**
  - Signature format: **CMS**
  - No unsigned nested components
- [ ] `spctl -a -vv Hiyo.app` returns **accepted**.

---

# **2. Hardened Runtime**

### **Required**
- [ ] `ENABLE_HARDENED_RUNTIME = YES`
- [ ] No unnecessary runtime exceptions:
  - [ ] `com.apple.security.cs.allow-jit` **disabled**
  - [ ] `com.apple.security.cs.allow-unsigned-executable-memory` **disabled**
  - [ ] `com.apple.security.cs.disable-library-validation` **disabled**

### **Allowed only if required**
- [ ] `com.apple.security.cs.allow-dyld-environment-variables` (should be **off**)
- [ ] `com.apple.security.cs.allow-objc-exception-throw` (rarely needed)

---

# **3. App Sandbox**

### **Required Entitlements**
- [ ] `com.apple.security.app-sandbox = true`
- [ ] `com.apple.security.files.user-selected.read-write = true`
- [ ] `com.apple.security.network.client = true` (only if needed)

### **Forbidden Entitlements**
- [ ] `com.apple.security.network.server` (unless the app truly runs a server)
- [ ] `com.apple.security.files.downloads.read-write`
- [ ] `com.apple.security.files.all`
- [ ] `com.apple.security.device.*` (camera, mic, unless explicitly used)

### **Verification**
- [ ] `codesign -d --entitlements :- Hiyo.app` matches the expected entitlements file.

---

# **4. Build Settings (Xcode)**

### **Required**
- [ ] `SWIFT_VERSION = 5.9` or later
- [ ] `MACOSX_DEPLOYMENT_TARGET = 14.0`
- [ ] `CODE_SIGN_INJECT_BASE_ENTITLEMENTS = YES`
- [ ] `DEAD_CODE_STRIPPING = YES`
- [ ] `ENABLE_STRICT_OBJC_MSGSEND = YES`
- [ ] `ENABLE_NS_ASSERTIONS = NO` (for release)
- [ ] `SWIFT_OPTIMIZATION_LEVEL = -Osize` or `-O`

### **Recommended**
- [ ] `OTHER_SWIFT_FLAGS` does **not** include experimental or unsafe flags
- [ ] `ENABLE_TESTABILITY = NO` in release builds
- [ ] `DEBUG_INFORMATION_FORMAT = dwarf-with-dsym`

---

# **5. Swift Package Manager Configuration**

### **Dependencies**
- [ ] All dependencies use **HTTPS URLs**
- [ ] No branch‑based dependencies (`.branch("main")`)
- [ ] Versions are pinned using `.exact` or `.upToNextMinor`
- [ ] No local path dependencies pointing outside the repo

### **Targets**
- [ ] Resources are bundled via `.process("Resources")`
- [ ] No unsafe linker flags
- [ ] No custom build scripts that modify system paths

---

# **6. MLX & Model Security**

### **Model Handling**
- [ ] All model downloads go through **SecureMLX.validateModelID**
- [ ] Model weights validated for:
  - [ ] File existence
  - [ ] Readability
  - [ ] Size bounds (1MB–20GB)
  - [ ] Allowed extensions (`safetensors`, `bin`, `mlx`, `weights`)
- [ ] Cache directory created with **0o700** permissions
- [ ] Symlink traversal checks enabled

### **GPU Safety**
- [ ] MLX GPU cache limit set adaptively
- [ ] MLX memory limit set adaptively
- [ ] `verifyMLXConfiguration()` passes

---

# **7. Sensitive Data Handling**

### **Secure Memory**
- [ ] All ephemeral keys use **SecureKey** or CryptoKit
- [ ] No sensitive data stored in:
  - [ ] UserDefaults
  - [ ] Logs
  - [ ] Crash reports
  - [ ] Temporary files without secure deletion

### **File Deletion**
- [ ] All sensitive files deleted via **SecureFileManager.secureDelete**

---

# **8. Logging & Diagnostics**

### **Allowed**
- [ ] High‑level operational logs
- [ ] Security event logs (no sensitive content)

### **Forbidden**
- [ ] Logging raw conversation text
- [ ] Logging model weights or paths
- [ ] Logging user‑selected file contents
- [ ] Logging full filesystem paths unnecessarily

---

# **9. Notarization**

### **Required**
- [ ] DMG notarized using `notarytool submit`
- [ ] Stapling completed:
  ```bash
  xcrun stapler staple Hiyo.dmg
  ```
- [ ] Verification:
  ```bash
  spctl -a -t open --context context:primary-signature -v Hiyo.dmg
  ```

---

# **10. Distribution Package (DMG)**

### **DMG Requirements**
- [ ] No hidden scripts or executables
- [ ] Only:
  - `Hiyo.app`
  - `/Applications` symlink
  - Optional README / LICENSE
- [ ] DMG created with:
  - Internet disable flag
  - Compressed UDZO format
  - No auto‑mount scripts

---

# **11. Final Release Checklist**

Before publishing a release:

- [ ] App builds cleanly with **no warnings**
- [ ] All entitlements verified
- [ ] All dependencies pinned
- [ ] All MLX security checks pass
- [ ] All sensitive data cleared
- [ ] App notarized and stapled
- [ ] DMG verified on a clean macOS system
- [ ] Version and build numbers updated
- [ ] App icon displays correctly
- [ ] No Gatekeeper warnings on launch
