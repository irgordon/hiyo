# Benchmark Rationale: Asynchronous Secure Deletion

## Context
The `SecureFileManager.secureDelete` function performs a secure deletion of files by overwriting them with random data three times before deleting the file. This process involves:
1.  Opening the file.
2.  Writing data equal to the file size (3 passes).
3.  Generating random data for each pass.
4.  Calling `sync()` (forcing a physical disk write) after each pass.
5.  Removing the item from the filesystem.

## Performance Issue
The `HiyoStore.clearAllData` method is annotated with `@MainActor`, meaning it executes on the main user interface thread. It calls `SecureMLX.clearAllCaches()`, which iteratively calls `SecureFileManager.secureDelete` for every file in the cache directory.

Executing blocking I/O operations, especially those involving `fsync` (via `sync()`), on the main thread causes the application UI to freeze (drop frames or become unresponsive) until the operation completes. If the cache contains large models (GBs in size), this freeze could last for seconds or minutes.

## Optimization Strategy
The optimization moves the blocking I/O operations in `secureDelete` to a background thread (using `Task.detached` or making the function `async`).

## Expected Improvement
*   **Metric:** Main Thread Block Time.
*   **Baseline:** The main thread is blocked for the entire duration of the secure delete operation (`Time(IO_Write * 3) + Time(fsync * 3) + Time(overhead)`).
*   **Optimized:** The main thread is blocked only for the time it takes to dispatch the asynchronous task (microseconds).

This change converts a synchronous, blocking operation into an asynchronous one, ensuring the UI remains responsive during data clearing operations.
