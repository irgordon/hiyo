# macOS App Audit Report: Hiyo

## Executive Summary

The `Hiyo` application demonstrates a strong commitment to security and privacy, utilizing robust patterns for file management, encryption, and concurrency. However, critical issues exist regarding missing code (`LLMModelFactory`), missing network entitlements required for model downloads, and unused entitlements that expand the attack surface unnecessarily.

## 1. Codebase Integrity (Critical)

### Finding: Missing `LLMModelFactory`
The class `LLMModelFactory` is referenced in `MLXProvider.swift` but is **missing** from the codebase.
- **Impact:** The application cannot compile or run.
- **Recommendation:** A stub implementation has been added to allow compilation, but the actual model loading logic must be imported from `mlx-swift-examples` or implemented.

## 2. Platform & Sandbox Alignment (High)

### Finding: Missing Network Client Entitlement
The app relies on `swift-transformers` and `MLX` to load models by ID (e.g., `mlx-community/Llama-3.2-1B...`). These libraries download models from Hugging Face Hub if not present. The `com.apple.security.network.client` entitlement is missing.
- **Impact:** Model loading will fail with a network error unless models are manually pre-loaded into the container.
- **Fix:** Added `com.apple.security.network.client`.

### Finding: Unnecessary Downloads Folder Access
The entitlement `com.apple.security.files.downloads.read-write` is present, but the code correctly uses `Application Support` and `Caches` for all operations.
- **Impact:** Unnecessary permission grant violates the Principle of Least Privilege.
- **Fix:** Removed `com.apple.security.files.downloads.read-write`.

## 3. Data Storage & Privacy (Good)

- **SecureFileManager:** Correctly uses `0o700`/`0o600` permissions and implements secure deletion.
- **HiyoStore:** Uses `CryptoKit` for exports and robust concurrency patterns (`@MainActor` + `Task.detached`).
- **Sanitization:** Input logs and chat titles are properly truncated.

## 4. MLX & Resource Safety (Good)

- **SecureMLX:** Implements strong symlink checks to prevent path traversal.
- **ResourceGuard:** Implements rate limiting and memory pressure checks.
- **GPU Limits:** Logic existed in both `HiyoApp` and `SecureMLX`.
- **Fix:** Deduplicated logic to use `SecureMLX.configureSafeLimits()` in `HiyoApp`.

## 5. UI & Design

- **Standards:** Uses native `Settings` scene, `WindowGroup`, and standard keyboard shortcuts.
- **Help:** Uses `NSWorkspace` safely for external links.

---

## Applied Fixes

1.  **Entitlements:** Removed Downloads access; Added Network Client access.
2.  **Code Cleanup:** Deduplicated GPU limit configuration in `HiyoApp.swift`.
3.  **Compilation Fix:** Added `LLMModelFactory.swift` stub.
