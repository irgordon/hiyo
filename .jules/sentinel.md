## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-04-10 - Insecure Directory Prefix Validation
**Vulnerability:** Path validation using raw `hasPrefix` (e.g., `path.hasPrefix(allowedPrefix)`) allowed directory traversal bypasses where an attacker could access `/allowed_dir_evil` when only `/allowed_dir` was permitted.
**Learning:** Simple string prefix checks are insufficient for path validation as they do not account for directory boundaries.
**Prevention:** Always validate directory containment by ensuring the path perfectly matches the allowed directory or starts with the allowed directory followed by a path separator (e.g., `path == prefix || path.hasPrefix(prefix + "/")`).

## 2026-06-25 - Incorrect Null Byte Validation
**Vulnerability:** In `InputValidator.swift`, the `validateModelIdentifier` function attempted to block null bytes by adding `"\\0"` (a string of a backslash and a zero) to the `blockedChars` array instead of `"\0"` (the actual null byte character).
**Learning:** Swift string literals interpret `"\0"` as the null character and `"\\0"` as a literal backslash followed by a zero. Using the latter fails to detect actual null byte injections.
**Prevention:** When checking for null bytes in Swift strings, always use `"\0"` or explicitly check the `unicodeScalars` for value `0`.
