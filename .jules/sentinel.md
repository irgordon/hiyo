## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-04-08 - Path Validation Vulnerability via hasPrefix
**Vulnerability:** Path validation using `path.hasPrefix(allowedPrefix)` without appending a trailing slash allowed directory traversal. An allowed prefix `/app/data` could be bypassed with a path like `/app/data_hacked/evil.txt`.
**Learning:** Raw `hasPrefix` checks in Swift are insufficient for strict directory validation because they match any string that begins with the prefix, not just subdirectories.
**Prevention:** Always validate directory paths by checking for an exact match (`path == prefix`) or by appending a trailing slash to the prefix (`path.hasPrefix(prefix + "/")`).
