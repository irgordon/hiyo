## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-04-10 - Insecure Directory Prefix Validation
**Vulnerability:** Path validation using raw `hasPrefix` (e.g., `path.hasPrefix(allowedPrefix)`) allowed directory traversal bypasses where an attacker could access `/allowed_dir_evil` when only `/allowed_dir` was permitted.
**Learning:** Simple string prefix checks are insufficient for path validation as they do not account for directory boundaries.
**Prevention:** Always validate directory containment by ensuring the path perfectly matches the allowed directory or starts with the allowed directory followed by a path separator (e.g., `path == prefix || path.hasPrefix(prefix + "/")`).

## 2024-05-24 - Null Byte Injection Literal Typo
**Vulnerability:** The application's input validator (`InputValidator.swift`) checked for the literal two-character string `"\\0"` instead of the actual null byte character `"\0"` when attempting to prevent null byte injection.
**Learning:** When sanitizing strings for special escape characters, typos like adding an extra backslash can make the check completely ineffective, as it looks for the literal representation instead of the control character itself.
**Prevention:** Ensure the exact string control characters like `"\0"` or `"\n"` are used in blocklists, not their literal string counterparts, and use unit tests that specifically attempt to inject the actual control character into the system.
