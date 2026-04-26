## 2026-02-01 - Security Controls Disconnected from Logic
**Vulnerability:** The application defined robust security controls in `SecureMLX.swift` (symlink checks, permission hardening) but failed to use them in the actual model loading logic (`MLXProvider.swift`), which relied on insecure defaults.
**Learning:** Having security helper classes is not enough; they must be explicitly integrated into the business logic. "Security Layers" documentation can drift from implementation reality.
**Prevention:** Use architectural enforcement (e.g., factory patterns that require security context) or linting rules to ensure security wrappers are used instead of raw APIs.

## 2026-04-10 - Insecure Directory Prefix Validation
**Vulnerability:** Path validation using raw `hasPrefix` (e.g., `path.hasPrefix(allowedPrefix)`) allowed directory traversal bypasses where an attacker could access `/allowed_dir_evil` when only `/allowed_dir` was permitted.
**Learning:** Simple string prefix checks are insufficient for path validation as they do not account for directory boundaries.
**Prevention:** Always validate directory containment by ensuring the path perfectly matches the allowed directory or starts with the allowed directory followed by a path separator (e.g., `path == prefix || path.hasPrefix(prefix + "/")`).

## 2026-04-16 - Incorrect Null Byte Escaping
**Vulnerability:** A literal backslash zero `"\\0"` was used in an array of blocked characters instead of the actual null byte character `"\0"`. This allowed null bytes to pass through the validation filter since it was looking for the literal string `\0` rather than the byte value 0.
**Learning:** In Swift, `"\0"` represents the actual null byte, while `"\\0"` represents two characters: a backslash and a zero.
**Prevention:** Always verify that escape sequences used in security validation actually represent the intended character/byte value rather than literal strings.

## 2026-04-26 - Unhandled SecRandomCopyBytes OSStatus
**Vulnerability:** The application was discarding the `OSStatus` returned by `SecRandomCopyBytes` using the `_ =` operator. This could result in a silent failure to generate random bytes, leading to the use of a predictable, all-zero cryptographic key.
**Learning:** System cryptographic and security APIs often return an `OSStatus` to indicate success or failure. Discarding these results can lead to severe security vulnerabilities, such as compromised encryption.
**Prevention:** System cryptographic and security APIs (like `SecRandomCopyBytes`) must never have their results discarded. Always explicitly verify the returned `OSStatus` is `errSecSuccess` and handle failures appropriately.

## 2026-04-26 - Node 20 GitHub Actions Deprecation
**Vulnerability:** The CI workflow `.github/workflows/ci.yml` uses actions that depend on Node.js 20, which is deprecated and will fail in future environments.
**Learning:** Outdated dependencies in CI can cause sudden pipeline failures, blocking security updates and features.
**Prevention:** CI workflows should be regularly audited and updated. For CodeQL, use `github/codeql-action/init@v4`.
