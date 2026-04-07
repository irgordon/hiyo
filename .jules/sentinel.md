## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-02-01 - Insecure Path Validation Check
**Vulnerability:** The `validateFilePath` function in `InputValidator.swift` used a raw `hasPrefix` check to verify if a path resided in an allowed directory.
**Learning:** A simple string prefix check like `hasPrefix("/path/to/dir")` is vulnerable to path traversal or directory spoofing, because `/path/to/dir_spoofed` would pass the check despite being outside the target directory.
**Prevention:** Path containment must be verified by checking for an exact match or using a trailing slash, e.g. `path == dir || path.hasPrefix(dir + "/")`.
