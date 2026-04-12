## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-04-10 - Insecure Directory Prefix Validation
**Vulnerability:** Path validation using raw `hasPrefix` (e.g., `path.hasPrefix(allowedPrefix)`) allowed directory traversal bypasses where an attacker could access `/allowed_dir_evil` when only `/allowed_dir` was permitted.
**Learning:** Simple string prefix checks are insufficient for path validation as they do not account for directory boundaries.
**Prevention:** Always validate directory containment by ensuring the path perfectly matches the allowed directory or starts with the allowed directory followed by a path separator (e.g., `path == prefix || path.hasPrefix(prefix + "/")`).

## 2026-04-12 - Ineffective Null Byte Validation in Swift
**Vulnerability:** A null byte injection prevention check was ineffective because it was checking for the literal string `"\0"` (backslash followed by zero) instead of the actual null byte character `"\0"`.
**Learning:** When trying to filter or block the null byte character in Swift strings, escaping the backslash results in a two-character literal (backslash + zero), completely bypassing the intended security check for actual null bytes.
**Prevention:** Always use the proper escape sequence `"\0"` without escaping the backslash when validating or stripping null bytes in Swift.
