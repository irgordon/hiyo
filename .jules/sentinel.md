## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-02-01 - Partial Path Traversal via `.hasPrefix`
**Vulnerability:** In `InputValidator.swift`, the `validateFilePath` method used `.hasPrefix` to ensure a file path was inside an allowed directory. This permitted a partial path traversal attack where a malicious directory name shares the same prefix (e.g., allowing `/tmp/dirFake` when `/tmp/dir` is the allowed prefix).
**Learning:** Simple string prefix matching is unsafe for directory boundary enforcement in file paths unless it explicitly accounts for path delimiters.
**Prevention:** Always check that the path either exactly matches the allowed prefix, or that the path starts with the allowed prefix followed immediately by a trailing slash (e.g., `pathString.hasPrefix(prefix + "/")`).
