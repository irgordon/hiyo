## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2025-05-18 - Path Traversal bypass via `hasPrefix`
**Vulnerability:** Path traversal protection in `InputValidator.swift` used `pathString.hasPrefix(allowedPrefix)` which incorrectly allowed maliciously crafted directories like `/AllowedPath-Malicious/`.
**Learning:** Raw string prefix matching on paths is dangerous as it doesn't account for path segment boundaries (the `/` character).
**Prevention:** Always check for an exact match or enforce a trailing slash (`hasPrefix(prefix + "/")`) when validating path prefixes, or use standard URL/Path matching APIs that are aware of directory separators.