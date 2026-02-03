# Benchmark Rationale

## Environment Limitations
The current execution environment lacks the Swift toolchain, preventing the compilation and execution of the benchmark files. Therefore, empirical performance data cannot be generated directly within this session.

## 1. Sidebar Search Optimization

### Baseline (Current Implementation)
The current implementation performs an **in-memory filter** on the entire dataset:
```swift
store.chats.filter {
    $0.title.localizedCaseInsensitiveContains(searchText) ||
    $0.messages.contains { $0.content.localizedCaseInsensitiveContains(searchText) }
}
```
* **Fetch:** Fetches *all* `Chat` objects from the persistent store into memory.
* **Faulting:** For every chat, it accesses `$0.messages`. In SwiftData/CoreData, relationships are often faults. Accessing `messages` triggers a fault fire, performing an additional fetch for the messages of that specific chat.
* **Complexity:** O(N * M) where N is the number of chats and M is the average number of messages per chat.
* **I/O:** Potentially N+1 separate I/O operations (1 for chats + N for messages).

### Optimization (SwiftData Predicate)
The proposed solution uses a `FetchDescriptor` with a `#Predicate`:
```swift
let predicate = #Predicate<Chat> { chat in
    chat.title.localizedStandardContains(searchText) ||
    chat.messages.contains { $0.content.localizedStandardContains(searchText) }
}
```
* **Execution:** The predicate is compiled into a SQL (or store-native) query.
* **I/O:** Single query execution against the database index (if available) or a single scan.
* **Memory:** Only the matching `Chat` objects (and their data) are instantiated in memory. Non-matching data remains on disk.
* **Complexity:** O(1) or O(log N) depending on indexing, handled by the database engine (SQLite).

## 2. Token Generation Persistence Optimization

### Baseline (Current Implementation)
The code iterates through a stream of tokens and saves to the database on *every single token*:
```swift
for try await token in stream {
    assistantContent += token
    assistantMessage.content = assistantContent
    try? store.modelContext.save()
}
```
* **I/O Overhead:** SwiftData (backed by SQLite) must serialize the context changes and commit a transaction to disk for every token.
* **Latency:** Disk I/O is orders of magnitude slower than memory operations. This introduces significant latency to the token generation loop, potentially making the UI stutter or the generation slower than the model's inference speed.
* **Wear:** Excessive write operations on SSDs (though modern SSDs are resilient, thousands of writes per message is inefficient).

### Optimization (Post-Loop Save)
The optimization moves the save operation outside the loop:
```swift
for try await token in stream {
    assistantContent += token
    assistantMessage.content = assistantContent
    // No save here
}
try? store.modelContext.save()
```
* **Correctness:** `assistantMessage` is a managed object in the main context. The UI (observing the context/object) will still reflect changes in real-time as `content` is updated in memory.
* **Efficiency:** Only one transaction commit is performed after the full message is generated.
* **Performance:** Eliminates (N-1) I/O operations, where N is the number of tokens (often hundreds or thousands).

## Conclusion
These optimizations focus on reducing I/O and memory overhead by leveraging the database engine for filtering and batching persistence operations.

## 3. Repeated Full Database Fetch Optimization

### Baseline (Current Implementation)
The `HiyoStore` methods `createChat`, `deleteChat`, `duplicateChat`, and `importChats` all call `fetchChats()` after modifying the database.
```swift
func createChat(...) {
    modelContext.insert(chat)
    try modelContext.save()
    fetchChats() // Triggers full fetch
}
```
* **Fetch:** Triggers a full database fetch of all `Chat` objects, sorted by modification date.
* **Complexity:** O(N) where N is the total number of chats. As the user's history grows, this operation becomes linearly slower.
* **Overhead:** Re-instantiates objects and rebuilds the `chats` array unnecessarily, even though we know exactly what changed.

### Optimization (Manual Array Update)
The optimization replaces the full fetch with targeted updates to the in-memory `chats` array:
```swift
// In createChat
chats.insert(chat, at: 0)

// In deleteChat
chats.removeAll { $0.id == chat.id }
```
* **Complexity:**
    * Create/Duplicate: O(1) (prepending to array).
    * Delete: O(N) (searching array to remove), but purely in-memory and much faster than database fetch + instantiation.
* **Efficiency:** avoids round-trip to the persistence store.
* **Correctness:** Since `Chat` is an observable class, changes to its properties (like `modifiedAt`) are reflected. However, for creation/deletion, updating the list structure manually keeps the UI in sync without re-fetching everything.
