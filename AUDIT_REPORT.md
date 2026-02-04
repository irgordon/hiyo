# Hiyo Security & Correctness Audit Report

**Date:** October 26, 2024
**Scope:** Full Repository Analysis
**Target:** macOS App Store (Sandbox, Privacy, Local-Only)

---

## Executive Summary

Hiyo demonstrates a strong commitment to security and privacy, with robust architectural decisions like `SecureMLX` resource limits, `SecureFileManager` permissions, and off-main-thread inference. However, critical issues exist in the model loading pipeline that break functionality, and the "Local-Only" promise conflicts with the dependency on `swift-transformers` for downloads. Additionally, a potential keychain misconfiguration could affect data persistence reliability.

## Severity Scale

- **Critical**: Breaks functionality or poses severe security risk.
- **High**: Major deviation from best practices or privacy promises.
- **Medium**: Correctness issue or potential edge-case bug.
- **Low**: Polish, style, or minor optimization.

---

## 1. MLX & Models

### [CRITICAL] Model Download Logic Broken by Premature Override
**File:** `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`
**Description:** `MLXProvider.loadModel` creates a `ModelConfiguration` with `overrideDirectory` set to the secure cache path. In `Load.swift`, the presence of `overrideDirectory` causes `prepareModelDirectory` to skip the `Hub.snapshot` call entirely. As a result, if the model is not already manually placed in the cache, loading will fail with a "file not found" error, and no download will ever be attempted.
**Remediation:**
Modify `MLXProvider` to checks if the model exists in `secureCacheDirectory`.
- If yes: Use `overrideDirectory`.
- If no: Do *not* set `overrideDirectory` (letting `Hub` download it), or manually invoke a download routine that places files into `secureCacheDirectory`.

### [HIGH] Naming Conflict in Shared Cache Directory
**File:** `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`, `SecureMLX.swift`
**Description:** `SecureMLX.secureCacheDirectory()` returns a single shared folder (`Hiyo/Models`). `MLXProvider` sets this as the override for *all* models. If multiple models are loaded, they will overwrite each other's `config.json` or conflict, as they are not namespaced by model ID within this directory.
**Remediation:**
Append the sanitized model ID to the cache directory path:
```swift
let cacheDir = try SecureMLX.secureCacheDirectory().appendingPathComponent(sanitizedId)
```

---

## 2. Storage & Privacy

### [HIGH] Potential Keychain Misconfiguration
**File:** `Hiyo/Sources/Hiyo/Security/SecureKeychain.swift`
**Description:** `save` uses the `.privateKeyUsage` flag in `SecAccessControlCreateWithFlags` for an item of class `kSecClassGenericPassword`. This flag is intended for private keys (usually generated in Secure Enclave) and may cause saving to fail or behave unpredictably for generic passwords.
**Remediation:**
Remove `.privateKeyUsage` for generic password items. Use `.userPresence` or `[]` (empty) depending on desired security level (biometric requirement).

### [LOW] Unencrypted Persistence (Standard Sandbox)
**File:** `Hiyo/Sources/Hiyo/Core/HiyoStore.swift`
**Description:** Chat history is stored in SwiftData (SQLite) without encryption. While protected by the App Sandbox, "Privacy" focused users often expect encryption-at-rest.
**Remediation:**
Enable `NSFileProtectionComplete` on the SQLite store directory via `SecureFileManager`.

---

## 3. Networking & Entitlements

### [HIGH] "Local-Only" vs. Network Dependency
**File:** `Hiyo.entitlements`, `Package.swift`
**Description:** The app claims "Local-Only" but requires `com.apple.security.network.client` to download models via `swift-transformers`. This library uses `URLSession.shared`, bypassing `SecureNetworkSession` blocking logic.
**Remediation:**
- Acknowledge this hybrid state: "Local Inference, Cloud Download".
- (Long Term) Implement a custom downloader using `SecureNetworkSession` and remove the dependency's network usage if possible, or strictly monitor network traffic.

### [MEDIUM] Force Unwrapped URLs
**File:** `Hiyo/Sources/Hiyo/Utils/Constants.swift`
**Description:** Usage of `URL(string: ...)!` causes crashes if the string is malformed.
**Remediation:**
Use `Optional` URLs or a safe initializer helper.

---

## 4. Concurrency & Performance

### [PASS] Inference Isolation
**File:** `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`
**Observation:** Inference runs on the `ModelContainer` actor, ensuring the Main Thread remains responsive.

### [PASS] KV-Cache Optimization
**File:** `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`
**Observation:** The generation loop correctly maintains and passes the KV-cache, ensuring O(1) generation complexity per token.

---

## 5. Security Helpers

### [PASS] Strict Input Validation
**File:** `Hiyo/Sources/Hiyo/Security/InputValidator.swift`
**Observation:** Input validation is very strict (blocking `<script` etc.). This is excellent for general security but may hinder technical users discussing code.

### [PASS] Secure Deletion
**File:** `Hiyo/Sources/Hiyo/Security/SecureFileManager.swift`
**Observation:** Implements overwriting and `sync` for file deletion, exceeding standard requirements.

---

## Recommendations for App Review

1.  **Fix the Model Loading Bug**: The app is currently non-functional for new users (cannot download models).
2.  **Clarify Network Usage**: Ensure the Privacy Policy/App Description explains that network is used *only* for model downloads.
3.  **Refine Keychain Usage**: Verify `SecureKeychain` works on actual hardware to prevent data loss.

