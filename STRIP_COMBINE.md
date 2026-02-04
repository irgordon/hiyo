# Strip Combine Report

## Executive Summary
This report analyzes the `Hiyo` codebase to identify dependencies on the Combine framework and proposes a migration path to Swift Concurrency (`async/await`) and the Observation framework (`@Observable`). This alignment with modern Swift standards (macOS 14+) will simplify data flow, improve performance, and reduce dependencies.

## Identified Files & Areas for Change

The following files explicitly import Combine or utilize Combine-related protocols (`ObservableObject`) and wrappers (`@Published`, `@ObservedObject`, `@EnvironmentObject`).

### 1. `Hiyo/Sources/Hiyo/HiyoState.swift`
*   **Current Usage**: Imports `Combine`. Conforms to `ObservableObject`. Uses `@Published` for UI state (`selectedModel`, `isSidebarVisible`) and metrics.
*   **Proposed Change**:
    *   Remove `import Combine`.
    *   Replace `ObservableObject` with the `@Observable` macro.
    *   Remove `@Published` property wrappers (Observation handles this automatically).
    *   Maintain `didSet` observers for `UserDefaults` persistence.

### 2. `Hiyo/Sources/Hiyo/Core/HiyoStore.swift`
*   **Current Usage**: Conforms to `ObservableObject`. Uses `@Published` for `currentChat`, `chats`, and `error`.
*   **Proposed Change**:
    *   Replace `ObservableObject` with `@Observable`.
    *   Remove `@Published` wrappers.
    *   Ensure all updates on `@MainActor` continue to function correctly (Observation is thread-safe for UI updates but main actor isolation is still best practice).

### 3. `Hiyo/Sources/Hiyo/Core/MLXProvider.swift`
*   **Current Usage**: Conforms to `ObservableObject`. Uses `@Published` for `state`, `isAvailable`, `memoryUsage`. Uses `objectWillChange.send()`.
*   **Proposed Change**:
    *   Replace `ObservableObject` with `@Observable`.
    *   Remove `@Published` wrappers.
    *   Remove `objectWillChange.send()` (mutating properties on an `@Observable` type automatically triggers updates).

### 4. `Hiyo/Sources/Hiyo/UI/Sidebar/ConversationSidebar.swift`
*   **Current Usage**: Imports `Combine`. Uses `AnyCancellable`, `.debounce`, `.removeDuplicates`, `.sink` for search text handling. Uses `@ObservedObject`.
*   **Proposed Change**:
    *   Remove `import Combine`.
    *   Remove `cancellables` storage.
    *   Replace `@ObservedObject` with standard variable declarations (e.g., `var store: HiyoStore`).
    *   Replace the Combine debounce pipeline with a structured concurrency approach using `.task` or `.onChange`:
        ```swift
        .task(id: searchText) {
            try? await Task.sleep(for: .milliseconds(250))
            debouncedSearchText = searchText
        }
        ```

### 5. `Hiyo/Sources/Hiyo/ContentView.swift`
*   **Current Usage**: Uses `@EnvironmentObject`, `@StateObject`. Uses `.onReceive` with `NotificationCenter` publishers.
*   **Proposed Change**:
    *   Replace `@EnvironmentObject` with `@Environment(HiyoState.self)`.
    *   Replace `@StateObject` with `@State`.
    *   Replace `.onReceive` with `.task` iterating over `NotificationCenter.default.notifications(named:)`, which provides an `AsyncSequence`, effectively removing the Combine publisher dependency.

### 6. `Hiyo/Sources/Hiyo/HiyoApp.swift`
*   **Current Usage**: Uses `@StateObject` to initialize `appState`. Uses `.environmentObject`.
*   **Proposed Change**:
    *   Replace `@StateObject` with `@State`.
    *   Replace `.environmentObject(appState)` with `.environment(appState)`.

### 7. Missing Files (Critical)
*   **Findings**: The files `ChatView.swift` and `ConversationInspector.swift` are referenced in `ContentView.swift` but were not found in the source tree during the review.
*   **Impact**: These files likely contain `@ObservedObject` or `@EnvironmentObject` references that must also be updated. Their absence prevents a complete migration and compilation of the refactored code.

## Performance Impact

1.  **Granular Invalidation**: Moving from `ObservableObject` to `@Observable` significantly improves SwiftUI performance. `ObservableObject` invalidates the *entire* view whenever *any* `@Published` property changes. `@Observable` tracks access at the property level, meaning views only redraw when the specific properties they read change. This is crucial for `HiyoState`, where high-frequency updates to `gpuUsage` or `memoryUsage` will no longer cause unrelated UI components (like the sidebar) to redraw.
2.  **Reduced Overhead**: Removing Combine pipelines in favor of `async/await` removes the allocation and management overhead of Publishers and Subscribers, resulting in a slightly lower memory footprint and cleaner stack traces.
3.  **Main Thread Safety**: The migration encourages stricter MainActor usage, ensuring UI updates are predictable and preventing data races.

## Final Analysis

The `Hiyo` codebase is well-structured for this migration. The heavy reliance on `ObservableObject` is typical for pre-Observation apps but is now technical debt given the target platform (macOS 14+).

**Recommendation**: Proceed with the migration immediately. The performance benefits for the "Local Intelligence" use case—specifically decoupling high-frequency inference metrics from static UI elements—are substantial. The missing `ChatView` and `ConversationInspector` files must be located or reconstructed before applying these changes to avoid build failures.
