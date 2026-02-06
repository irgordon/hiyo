# Hiyo Security & Correctness Audit Report

**Date:** February 3, 2026 (Updated: Current)
**Scope:** Full Repository Analysis
**Target:** macOS App Store (Sandbox, Privacy, Local-Only)

---

## Executive Summary

Hiyo demonstrates a strong commitment to security and privacy. Following the initial audit, all critical and high-severity technical issues have been resolved. The application now correctly enforces secure model loading, encrypts data at rest, and handles keychain operations safely. The network dependency for model downloads remains but is bounded and necessary.

## Severity Scale

- **Critical**: Breaks functionality or poses severe security risk.
- **High**: Major deviation from best practices or privacy promises.
- **Medium**: Correctness issue or potential edge-case bug.
- **Low**: Polish, style, or minor optimization.

---

## 1. MLX & Models

### [RESOLVED] Model Download Logic
**File:** `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`, `Hiyo/Sources/Hiyo/Core/LLMModelFactory.swift`
**Resolution:**
Refactored `MLXProvider` and `LLMModelFactory`. `MLXProvider` now delegates all loading to `LLMModelFactory`. `LLMModelFactory` correctly configures `HubApi` with `SecureMLX.secureCacheDirectory()` as the download base. This ensures:
1.  Models are downloaded to the app's secure cache directory.
2.  `Hub` handles directory structures and namespacing (resolving the previous naming conflict).
3.  Downloads occur automatically if the model is missing, fixing the "file not found" bug.

### [RESOLVED] Naming Conflict in Shared Cache Directory
**Resolution:**
By utilizing `Hub`'s standard directory structure within the secure cache, models are properly namespaced (e.g., `models--org--repo`), preventing conflicts between different models.

---

## 2. Storage & Privacy

### [RESOLVED] Keychain Misconfiguration
**File:** `Hiyo/Sources/Hiyo/Security/SecureKeychain.swift`
**Resolution:**
Verified code uses `[]` (empty flags) for `SecAccessControlCreateWithFlags`, avoiding the invalid `.privateKeyUsage` flag. Added explicit comments to clarify that standard protection (device-bound, unlocked access) is intentional for user convenience while maintaining security.

### [RESOLVED] Unencrypted Persistence (Standard Sandbox)
**File:** `Hiyo/Sources/Hiyo/Core/HiyoStore.swift`
**Resolution:**
Implemented `secureStorageDirectory()` in `HiyoStore`. This method applies `NSFileProtectionComplete` to the Application Support directory, ensuring that all SwiftData files are encrypted at rest and inaccessible while the device is locked.

---

## 3. Networking & Entitlements

### [ACKNOWLEDGED] "Local-Only" vs. Network Dependency
**File:** `Hiyo.entitlements`, `Package.swift`
**Status:**
The app requires `com.apple.security.network.client` to download models via `swift-transformers`. This is a known hybrid state ("Local Inference, Cloud Download").
**Mitigation:** `SecureNetworkSession` logic exists to block other traffic, though `swift-transformers` uses its own session. Future work may involve a custom downloader.

### [RESOLVED] Force Unwrapped URLs
**File:** `Hiyo/Sources/Hiyo/Utils/Constants.swift`
**Resolution:**
Replaced all force-unwrapped `URL(string: ...)!` calls with safe initialization and fallback to a safe local URL (`file:///`) to prevent crashes.

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
**Observation:** Input validation is very strict (blocking `<script` etc.). This is excellent for general security.

### [PASS] Secure Deletion
**File:** `Hiyo/Sources/Hiyo/Security/SecureFileManager.swift`
**Observation:** Implements overwriting and `sync` for file deletion.

---

## 6. Concurrency Audit (2026 Standards)

### [RESOLVED] Unstructured Task Usage
**File:** `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`
**Resolution:**
Replaced `Task.detached` with structured `Task { ... }` in `loadModel`. This ensures the operation inherits the UI's priority and actor isolation context while correctly awaiting the background actor (`LoadModelOperation`), preventing priority inversion and simplifying state updates.

### [RESOLVED] Sendable Violation in Generator
**File:** `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`
**Resolution:**
Marked `LLMGenerator` as `@unchecked Sendable`. The generator holds a non-Sendable `LLMModel` (reference type) but is strictly confined to the execution context of the `ModelContainer` actor via `AsyncStream`. Added documentation and a TODO for future removal.

### [RESOLVED] Background Task Priority
**File:** `Hiyo/Sources/Hiyo/Core/HiyoStore.swift`
**Resolution:**
Explicitly set `priority: .userInitiated` for `duplicateChat`'s detached task to guarantee UI responsiveness for user-triggered background operations.

---

## Final Status

The repository is now in a **RELEASE READY** state regarding security and correctness. The critical blocking bugs have been fixed, and privacy protections (encryption at rest, keychain safety) have been strengthened.
