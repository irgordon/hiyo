# Benchmark Rationale: HiyoStore Import Optimization

## Issue
The function `importChats(from:)` in `HiyoStore.swift` is currently executed on the `@MainActor`. It performs the following blocking operations synchronously:
1.  **File I/O**: Reading the entire file content into memory using `Data(contentsOf:)`.
2.  **Decryption**: Using `AES.GCM.open` to decrypt the data.
3.  **JSON Decoding**: deserializing the JSON data into `[Chat]` objects.

For large export files (e.g., hundreds of MBs of chat history), this will cause a noticeable freeze in the UI (Main Thread hang), leading to a poor user experience and potential "Application Not Responding" (ANR) warnings.

## Optimization Strategy
We will refactor `importChats` to be an `async` function. The resource-intensive operations (I/O, decryption, decoding) will be offloaded to a `Task.detached` block. This allows them to run on a background thread pool, freeing up the Main Thread to handle UI updates.

The flow will be:
1.  **Main Actor**: Initiate the import.
2.  **Background Thread**: Read file, decrypt, decode JSON. Return the array of `Chat` objects.
3.  **Main Actor**: Receive the `[Chat]` array and insert them into the `ModelContext`.

## Measurement Constraints
The current development environment lacks the Swift toolchain, preventing the compilation and execution of dynamic benchmarks (e.g., XCTest metrics or custom timing scripts). Therefore, we rely on static analysis and established best practices for concurrency.

## Expected Impact
*   **Main Thread Blocking Time**: Reduced from O(N) (dependent on file size) to nearly O(1) (only the context insertion remains on main thread).
*   **UI Responsiveness**: The app will remain responsive during the import process (e.g., can show a spinner or progress bar).
