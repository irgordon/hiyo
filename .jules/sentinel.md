## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-04-10 - Insecure Directory Prefix Validation
**Vulnerability:** Path validation using raw `hasPrefix` (e.g., `path.hasPrefix(allowedPrefix)`) allowed directory traversal bypasses where an attacker could access `/allowed_dir_evil` when only `/allowed_dir` was permitted.
**Learning:** Simple string prefix checks are insufficient for path validation as they do not account for directory boundaries.
**Prevention:** Always validate directory containment by ensuring the path perfectly matches the allowed directory or starts with the allowed directory followed by a path separator (e.g., `path == prefix || path.hasPrefix(prefix + "/")`).

## 2026-04-13 - Incorrect Null Byte Validation
**Vulnerability:** String validation checks for null bytes used the literal backslash followed by a zero (`"\\0"`) instead of the actual null byte character (`"\0"`). This meant the validation successfully blocked the literal string `\0`, but allowed actual null byte injection payloads.
**Learning:** In Swift, `\0` represents the actual null byte, while `\\0` represents two characters: a backslash and a zero. Security validation logic that relies on string matching must use the correct escape sequences to target the intended raw bytes.
**Prevention:** When performing null byte injection prevention in Swift string validations, ensure the actual null byte character `"\0"` is used rather than the literal backslash and zero `"\\0"`.
