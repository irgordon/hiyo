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

## 2026-05-11 - Copy-On-Write (COW) Memory Wiping Bypass
**Vulnerability:** In `SecureMemory.swift`, the `destroy()` method used `guard var data = value` to safely unwrap the optional. This triggered Swift's Copy-On-Write (COW) semantics when the `data` buffer was mutated via `withUnsafeMutableBytes`, causing the zeroing operation to run on a copy while the original buffer containing sensitive data was left intact in memory.
**Learning:** Assigning a Swift value type (like `Data`) to a local variable and then mutating it can trigger COW when the underlying storage is shared or not uniquely referenced. In this case, both the stored property and the local copy referenced the same storage, so mutating the local variable caused the wipe to occur on a copied buffer instead of the original allocation.
**Prevention:** When securely wiping memory, avoid mutating a separate local copy of a COW-backed value while its storage may still be shared. Instead, mutate the original optional property directly (for example, `value?.withUnsafeMutableBytes { ... }`) so the intended in-place buffer is zeroed.

## 2026-06-25 - Unchecked Cryptographic Random Generation
**Vulnerability:** In `HiyoStore.swift`, the result of `SecRandomCopyBytes` was discarded using the `_ =` operator when generating the encryption key. If random byte generation failed (e.g., due to a lack of entropy), the buffer would remain filled with zeros, resulting in a predictable, zeroed symmetric encryption key being used and stored in the Keychain.
**Learning:** System cryptographic APIs that populate memory buffers by reference often return an `OSStatus` or similar code to indicate success or failure. Discarding this return value allows execution to proceed with uninitialized or zeroed memory, leading to silent security bypasses.
**Prevention:** Never discard the result of critical security APIs like `SecRandomCopyBytes`. Always explicitly verify the returned `OSStatus` is `errSecSuccess` and securely handle the failure case (e.g., by throwing an error) to prevent proceeding with invalid keys.
