# View Lifecycle in SwiftUI: Complete Guide

## Table of Contents
1. [What is View Lifecycle?](#what-is-view-lifecycle)
2. [The Complete Lifecycle Flow](#the-complete-lifecycle-flow)
3. [Lifecycle Phases](#lifecycle-phases)
4. [Lifecycle Modifiers](#lifecycle-modifiers)
5. [onAppear vs task](#onappear-vs-task)
6. [View vs Attribute Lifecycle](#view-vs-attribute-lifecycle)
7. [Lifecycle in Different Contexts](#lifecycle-in-different-contexts)
8. [Common Lifecycle Patterns](#common-lifecycle-patterns)
9. [Common Lifecycle Problems](#common-lifecycle-problems)
10. [Best Practices](#best-practices)

---

## What is View Lifecycle?

### Definition

**View Lifecycle** refers to the stages a view goes through from when it first appears on screen until it's removed.

**Key Distinction:** SwiftUI has two lifecycles happening simultaneously:

1. **View Struct Lifecycle** - The temporary struct (milliseconds)
2. **Attribute Lifecycle** - The persistent state container (until view removed)

This guide focuses on the **Attribute Lifecycle** - the "real" lifecycle users care about.

---

### The Lifecycle Stages

```
┌─────────────────────────────────────────────────────────────┐
│ 1. INITIALIZATION                                           │
│    View struct created for first time                       │
│    AttributeGraph allocates attribute + @State storage      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. APPEAR                                                    │
│    View becomes visible on screen                           │
│    onAppear() called                                        │
│    task { } starts                                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. ACTIVE                                                    │
│    View is visible and interactive                          │
│    body runs on state changes                               │
│    @State persists across updates                           │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. DISAPPEAR                                                 │
│    View removed from screen (but may still exist)           │
│    onDisappear() called                                     │
│    task { } cancelled                                       │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. DEALLOCATION                                              │
│    View's identity destroyed                                │
│    AttributeGraph deallocates attribute                     │
│    @State storage destroyed                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## The Complete Lifecycle Flow

### Example: Navigation Flow

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Go to Detail") {
                DetailView()
            }
        }
    }
}

struct DetailView: View {
    @State private var count = 0
    
    init() {
        print("1. Init called")
    }
    
    var body: some View {
        Text("Count: \(count)")
            .onAppear {
                print("2. onAppear called")
            }
            .onDisappear {
                print("3. onDisappear called")
            }
    }
}
```

**Timeline:**

```
User taps "Go to Detail":

Time 0ms: NavigationStack prepares to push DetailView
  → Creates DetailView struct
  → print("1. Init called")
  → SwiftUI creates attribute for DetailView
  → Allocates @State storage: { count: 0 }
  
Time 50ms: DetailView becomes visible on screen
  → print("2. onAppear called")
  → View is now in "Active" phase

User taps back button:

Time 5000ms: NavigationStack pops DetailView
  → print("3. onDisappear called")
  → View removed from screen
  
Time 5100ms: Navigation animation completes
  → DetailView's identity destroyed
  → AttributeGraph deallocates attribute
  → @State storage destroyed
  → count lost forever
```

---

### Multiple onAppear/onDisappear Calls

**Important:** onAppear and onDisappear can be called **multiple times** for the same view!

```swift
struct ScrollingView: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<100) { index in
                    RowView(index: index)
                }
            }
        }
    }
}

struct RowView: View {
    let index: Int
    
    var body: some View {
        Text("Row \(index)")
            .onAppear {
                print("Row \(index) appeared")
            }
            .onDisappear {
                print("Row \(index) disappeared")
            }
    }
}
```

**User scrolls down:**
```
Row 0 appeared
Row 1 appeared
...
Row 10 appeared

(User scrolls - Row 0 goes off screen)
Row 0 disappeared

(User scrolls back up)
Row 0 appeared  ← Called AGAIN!
```

**Key point:** onAppear/onDisappear = visibility events, NOT lifecycle start/end!

---

## Lifecycle Phases

### Phase 1: Initialization

**When:** View struct created for first time with new identity

**What happens:**
1. `init()` runs
2. AttributeGraph creates attribute
3. @State storage allocated with initial values
4. Body NOT called yet

**Example:**

```swift
struct MyView: View {
    @State private var count = 0
    let configuration: String
    
    init(configuration: String) {
        self.configuration = configuration
        print("Init: configuration = \(configuration)")
        // Can't access @State here - not initialized yet!
    }
    
    var body: some View {
        Text("Count: \(count)")
    }
}
```

**Timeline:**
```
1. init() runs
2. AttributeGraph allocates storage: { count: 0 }
3. Later, when rendering: body runs
```

---

### Phase 2: Appear

**When:** View becomes visible on screen

**What happens:**
1. View rendered for first time
2. `onAppear` called
3. `task { }` starts
4. Transition animations play (if any)

**Example:**

```swift
struct ProfileView: View {
    @State private var user: User?
    
    var body: some View {
        VStack {
            if let user {
                Text(user.name)
            }
        }
        .onAppear {
            loadUser()  // ← Perfect place to load data
        }
    }
    
    func loadUser() {
        // Fetch from network/database
    }
}
```

**When onAppear is called:**
- View added to visible hierarchy
- Navigation pushed
- Tab becomes active
- Scroll brings view on screen (LazyVStack/LazyHStack)
- Sheet presented

---

### Phase 3: Active

**When:** View is visible and interactive

**What happens:**
- User interacts with view
- State changes trigger body updates
- View struct recreated many times
- Attribute persists throughout
- @State values maintained

**Example:**

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        // This body runs many times during Active phase
        VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}
```

**During active phase:**
```
User taps button
  → count changes: 0 → 1
  → body runs (view struct recreated)
  → New view tree created
  → AttributeGraph updated
  → Screen renders new count

User taps again
  → count changes: 1 → 2
  → body runs again
  → ... cycle continues

View remains in Active phase entire time
onAppear NOT called again
```

---

### Phase 4: Disappear

**When:** View removed from visible hierarchy

**What happens:**
1. `onDisappear` called
2. `task { }` cancelled
3. Transition animations play (if any)
4. View no longer visible

**Important:** Attribute may still exist! @State persists!

**Example:**

```swift
struct DetailView: View {
    @State private var timer: Timer?
    
    var body: some View {
        Text("Detail")
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    print("Tick")
                }
            }
            .onDisappear {
                timer?.invalidate()  // ← Cleanup!
                timer = nil
            }
    }
}
```

**Why cleanup in onDisappear:**
- Timers keep running if not stopped
- Network requests waste resources
- Observers/delegates cause memory leaks

---

### Phase 5: Deallocation

**When:** View's identity destroyed (removed from view tree entirely)

**What happens:**
1. AttributeGraph destroys attribute
2. @State storage deallocated
3. All state lost
4. No more callbacks possible

**Example:**

```swift
struct ConditionalView: View {
    @State private var showDetail = false
    
    var body: some View {
        VStack {
            Toggle("Show Detail", isOn: $showDetail)
            
            if showDetail {
                DetailView()  // ← Identity created
            }
            // When showDetail = false, identity destroyed
        }
    }
}
```

**Timeline:**
```
showDetail = true:
  → DetailView identity created
  → Attribute allocated
  → @State initialized
  → onAppear called
  → Active phase

showDetail = false:
  → onDisappear called
  → Identity destroyed
  → Attribute deallocated
  → @State lost

showDetail = true again:
  → NEW identity created (fresh start)
  → NEW attribute allocated
  → @State reinitialized (reset!)
  → onAppear called again
```

---

## Lifecycle Modifiers

### .onAppear()

**Signature:**
```swift
func onAppear(perform action: @escaping () -> Void) -> some View
```

**When called:**
- View becomes visible on screen

**Common uses:**
- Load data
- Start animations
- Register observers
- Track analytics

**Example:**

```swift
struct NewsView: View {
    @State private var articles: [Article] = []
    
    var body: some View {
        List(articles) { article in
            Text(article.title)
        }
        .onAppear {
            loadArticles()
        }
    }
    
    func loadArticles() {
        Task {
            articles = try await api.fetchArticles()
        }
    }
}
```

---

### .onDisappear()

**Signature:**
```swift
func onDisappear(perform action: @escaping () -> Void) -> some View
```

**When called:**
- View removed from visible hierarchy

**Common uses:**
- Cancel timers
- Cancel network requests
- Unregister observers
- Save state
- Track analytics

**Example:**

```swift
struct VideoPlayer: View {
    @State private var player: AVPlayer?
    
    var body: some View {
        VideoPlayerView(player: player)
            .onAppear {
                player = AVPlayer(url: videoURL)
                player?.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}
```

---

### .task { }

**Signature:**
```swift
func task(priority: TaskPriority = .userInitiated, 
          @_implicitSelfCapture _ action: @escaping @Sendable () async -> Void) -> some View
```

**When it runs:**
- Starts when view appears
- Automatically cancelled when view disappears
- Supports async/await

**Example:**

```swift
struct UserProfile: View {
    @State private var user: User?
    
    var body: some View {
        VStack {
            if let user {
                Text(user.name)
            } else {
                ProgressView()
            }
        }
        .task {
            // Starts when view appears
            user = try? await api.fetchUser()
            // Cancelled automatically if view disappears
        }
    }
}
```

**Advantages over onAppear:**
1. Async/await support
2. Automatic cancellation
3. Structured concurrency

---

### .task(id:) { }

**Signature:**
```swift
func task<T: Equatable>(id value: T, 
                        priority: TaskPriority = .userInitiated,
                        @_implicitSelfCapture _ action: @escaping @Sendable () async -> Void) -> some View
```

**When it runs:**
- Starts when view appears OR when `id` changes
- Cancelled when view disappears OR when `id` changes

**Example:**

```swift
struct UserProfile: View {
    let userID: UUID
    @State private var user: User?
    
    var body: some View {
        VStack {
            if let user {
                Text(user.name)
            }
        }
        .task(id: userID) {
            // Runs when userID changes
            user = try? await api.fetchUser(id: userID)
        }
    }
}
```

**Use case:** Re-fetch data when parameter changes

---

### .onChange(of:) { }

**Signature:**
```swift
func onChange<V: Equatable>(of value: V, 
                            initial: Bool = false,
                            _ action: @escaping (V, V) -> Void) -> some View
```

**When it runs:**
- When observed value changes
- Optionally on initial appearance (if `initial: true`)

**Example:**

```swift
struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [Item] = []
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
            List(results) { item in
                Text(item.name)
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            performSearch(query: newValue)
        }
    }
    
    func performSearch(query: String) {
        Task {
            results = try await api.search(query: query)
        }
    }
}
```

**Note:** onChange is NOT a lifecycle event, but often used in lifecycle management.

---

### Deprecated Modifiers

**iOS 13-16:**
```swift
.onAppear { }          // Still valid
.onDisappear { }       // Still valid
.onReceive(publisher)  // Replaced by .task in most cases
```

---

## onAppear vs task

### Key Differences

| Feature | onAppear | task |
|---------|----------|------|
| Async support | ❌ No | ✅ Yes |
| Auto cancellation | ❌ No | ✅ Yes |
| Structured concurrency | ❌ No | ✅ Yes |
| Multiple calls | ✅ Yes | ✅ Yes |
| iOS version | 13+ | 15+ |

---

### When to Use Each

**Use onAppear when:**
- Synchronous work
- Need iOS 13/14 support
- Simple setup tasks

```swift
.onAppear {
    print("View appeared")
    isVisible = true
}
```

---

**Use task when:**
- Async operations
- Network requests
- Need automatic cancellation
- Modern Swift concurrency

```swift
.task {
    data = try await api.fetch()
}
```

---

### Migration Example

**Old (onAppear):**

```swift
struct OldView: View {
    @State private var data: Data?
    @State private var task: Task<Void, Never>?
    
    var body: some View {
        Text("Data")
            .onAppear {
                task = Task {
                    data = try? await api.fetch()
                }
            }
            .onDisappear {
                task?.cancel()  // ← Manual cancellation
            }
    }
}
```

**New (task):**

```swift
struct NewView: View {
    @State private var data: Data?
    
    var body: some View {
        Text("Data")
            .task {
                data = try? await api.fetch()
                // ← Automatically cancelled on disappear
            }
    }
}
```

---

## View vs Attribute Lifecycle

### Two Lifecycles Running Simultaneously

**View Struct Lifecycle (Short):**
```
Created → Used → Destroyed (milliseconds)
```

Every body call creates new view struct.

---

**Attribute Lifecycle (Long):**
```
Created → Exists → Destroyed (seconds/minutes)
```

Persists across many body calls.

---

### Example Showing Both

```swift
struct LifecycleDemo: View {
    @State private var count = 0
    
    init() {
        print("View struct init")  // ← Called on EVERY body execution
    }
    
    var body: some View {
        let _ = print("Body called")  // ← Called on EVERY update
        
        VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
        .onAppear {
            print("Attribute appeared")  // ← Called once when visible
        }
    }
}
```

**Output when view appears and user taps 3 times:**

```
View struct init        ← First render
Body called
Attribute appeared      ← onAppear

View struct init        ← count changed, body runs
Body called

View struct init        ← count changed again
Body called

View struct init        ← count changed again
Body called
```

**Key insight:** 
- View struct created 4 times
- onAppear called 1 time
- Attribute persists entire time

---

## Lifecycle in Different Contexts

### Navigation

```swift
NavigationStack {
    NavigationLink("Detail") {
        DetailView()
    }
}
```

**Lifecycle:**
```
User taps link:
  → DetailView init
  → Attribute created
  → @State allocated
  → onAppear called

User navigates back:
  → onDisappear called
  → Identity destroyed
  → Attribute deallocated
  → @State lost
```

---

### Tabs

```swift
TabView {
    HomeView()
        .tabItem { Label("Home", systemImage: "house") }
    
    ProfileView()
        .tabItem { Label("Profile", systemImage: "person") }
}
```

**Lifecycle:**
```
App launch:
  → Both views initialized
  → Both attributes created
  → Only active tab calls onAppear

User switches tabs:
  → Old tab: onDisappear
  → New tab: onAppear
  → Both attributes persist!
  → @State persists in both tabs
```

**Important:** Tab switching does NOT destroy views!

---

### Sheets/Fullscreen Covers

```swift
.sheet(isPresented: $showSheet) {
    SheetView()
}
```

**Lifecycle:**
```
showSheet = true:
  → SheetView init
  → Attribute created
  → onAppear called

User dismisses:
  → onDisappear called
  → Identity destroyed
  → Attribute deallocated
  → @State lost

showSheet = true again:
  → Fresh SheetView created (state reset)
```

---

### Lists (LazyVStack/LazyHStack)

```swift
List {
    ForEach(items) { item in
        RowView(item: item)
    }
}
```

**Lifecycle:**
```
Row scrolls on screen:
  → RowView init
  → Attribute created
  → onAppear called

Row scrolls off screen:
  → onDisappear called
  → Attribute MAY persist (SwiftUI's optimization)
  → @State preserved

Row scrolls back on screen:
  → onAppear called AGAIN
  → Same attribute reused
  → @State persisted!
```

**Key point:** Lazy containers preserve state for off-screen views for performance.

---

### Conditional Views

```swift
if showView {
    MyView()
}
```

**Lifecycle:**
```
showView = true:
  → MyView identity created
  → Attribute allocated
  → onAppear called

showView = false:
  → onDisappear called
  → Identity destroyed immediately
  → Attribute deallocated
  → @State lost

showView = true again:
  → NEW identity (state reset)
```

---

## Common Lifecycle Patterns

### Pattern 1: Load Data on Appear

```swift
struct ArticleList: View {
    @State private var articles: [Article] = []
    @State private var isLoading = false
    
    var body: some View {
        List(articles) { article in
            Text(article.title)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            isLoading = true
            defer { isLoading = false }
            
            articles = try await api.fetchArticles()
        }
    }
}
```

---

### Pattern 2: Cleanup on Disappear

```swift
struct TimerView: View {
    @State private var timer: Timer?
    @State private var count = 0
    
    var body: some View {
        Text("Count: \(count)")
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    count += 1
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
    }
}
```

---

### Pattern 3: Re-fetch on Parameter Change

```swift
struct UserProfile: View {
    let userID: UUID
    @State private var user: User?
    
    var body: some View {
        VStack {
            if let user {
                Text(user.name)
            }
        }
        .task(id: userID) {
            // Re-runs when userID changes
            user = try? await api.fetchUser(id: userID)
        }
    }
}
```

---

### Pattern 4: Track Analytics

```swift
struct ProductDetail: View {
    let product: Product
    
    var body: some View {
        ScrollView {
            // Product content
        }
        .onAppear {
            analytics.track("product_viewed", properties: [
                "product_id": product.id,
                "product_name": product.name
            ])
        }
    }
}
```

---

### Pattern 5: Debounced Search

```swift
struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [Item] = []
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
            List(results) { item in
                Text(item.name)
            }
        }
        .onChange(of: searchText) { oldValue, newValue in
            searchTask?.cancel()
            
            searchTask = Task {
                try? await Task.sleep(for: .milliseconds(300))  // Debounce
                
                if !Task.isCancelled {
                    results = try await api.search(query: newValue)
                }
            }
        }
    }
}
```

---

### Pattern 6: Refresh on Re-appear

```swift
struct NotificationsList: View {
    @State private var notifications: [Notification] = []
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        List(notifications) { notification in
            Text(notification.message)
        }
        .task {
            notifications = try await api.fetchNotifications()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    notifications = try await api.fetchNotifications()
                }
            }
        }
    }
}
```

---

## Common Lifecycle Problems

### Problem 1: Retain Cycles in Closures

```swift
// ❌ BAD: Retain cycle
struct BadView: View {
    @State private var data: Data?
    
    var body: some View {
        Text("Data")
            .onAppear {
                loadData { result in
                    self.data = result  // ← Captures self strongly
                }
            }
    }
    
    func loadData(completion: @escaping (Data) -> Void) {
        // Long-running operation
    }
}
```

**Problem:** If view disappears before completion, closure keeps view alive.

**Solution:**

```swift
// ✓ GOOD: Weak self
.onAppear {
    loadData { [weak self] result in
        self?.data = result
    }
}

// Or use task (automatic cancellation):
.task {
    data = await loadData()
}
```

---

### Problem 2: Multiple onAppear Calls

```swift
// ❌ BAD: Assumes onAppear called once
struct BadView: View {
    @State private var hasLoaded = false
    
    var body: some View {
        List {
            // Content
        }
        .onAppear {
            loadData()  // ← Called every time view appears!
        }
    }
}
```

**Problem:** In LazyVStack, onAppear called when scrolling back to view.

**Solution: Track if already loaded**

```swift
// ✓ GOOD: Only load once
@State private var hasLoaded = false

.onAppear {
    guard !hasLoaded else { return }
    hasLoaded = true
    loadData()
}
```

---

### Problem 3: Not Cancelling Tasks

```swift
// ❌ BAD: Task keeps running
struct BadView: View {
    @State private var data: Data?
    
    var body: some View {
        Text("Data")
            .onAppear {
                Task {
                    // Long operation
                    data = try await api.fetch()
                }
            }
    }
}
```

**Problem:** Task continues even after view disappears.

**Solution:**

```swift
// ✓ GOOD: Use .task (auto cancellation)
.task {
    data = try await api.fetch()
}

// Or manual:
@State private var task: Task<Void, Never>?

.onAppear {
    task = Task {
        data = try await api.fetch()
    }
}
.onDisappear {
    task?.cancel()
}
```

---

### Problem 4: Accessing Deallocated State

```swift
// ❌ BAD: Completion after view gone
struct BadView: View {
    @State private var result: String?
    
    var body: some View {
        Text(result ?? "Loading")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    result = "Done"  // ← May crash if view deallocated
                }
            }
    }
}
```

**Problem:** Delayed closure may execute after view destroyed.

**Solution:**

```swift
// ✓ GOOD: Use task with proper lifecycle
.task {
    try? await Task.sleep(for: .seconds(5))
    
    if !Task.isCancelled {
        result = "Done"
    }
}
```

---

### Problem 5: Forgetting Cleanup

```swift
// ❌ BAD: Observer not removed
struct BadView: View {
    var body: some View {
        Text("View")
            .onAppear {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(handleNotification),
                    name: .someNotification,
                    object: nil
                )
            }
            // ← Missing onDisappear to remove observer!
    }
}
```

**Problem:** Observer leaks, causes crashes.

**Solution:**

```swift
// ✓ GOOD: Cleanup in onDisappear
@State private var observer: NSObjectProtocol?

.onAppear {
    observer = NotificationCenter.default.addObserver(
        forName: .someNotification,
        object: nil,
        queue: .main
    ) { notification in
        // Handle
    }
}
.onDisappear {
    if let observer {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

---

### Problem 6: Expensive Work in onAppear

```swift
// ❌ BAD: Blocks main thread
struct BadView: View {
    @State private var processedData: [Item] = []
    
    var body: some View {
        List(processedData) { item in
            Text(item.name)
        }
        .onAppear {
            // Expensive synchronous work
            processedData = rawData.map { processExpensively($0) }
        }
    }
}
```

**Problem:** UI freezes during onAppear.

**Solution:**

```swift
// ✓ GOOD: Async processing
.task {
    processedData = await Task.detached {
        rawData.map { processExpensively($0) }
    }.value
}
```

---

## Best Practices

### 1. Prefer .task over onAppear for Async Work

```swift
// ✓ GOOD
.task {
    data = try await api.fetch()
}

// Instead of:
.onAppear {
    Task {
        data = try await api.fetch()
    }
}
```

**Benefits:**
- Automatic cancellation
- Structured concurrency
- Cleaner code

---

### 2. Always Clean Up Resources

```swift
.onAppear {
    startTimer()
    registerObserver()
}
.onDisappear {
    stopTimer()        // ← Don't forget!
    unregisterObserver()
}
```

**Resources requiring cleanup:**
- Timers
- Observers
- Subscriptions
- Network connections
- File handles

---

### 3. Use .task(id:) for Parameter-Dependent Work

```swift
.task(id: selectedID) {
    // Re-runs when selectedID changes
    data = try await api.fetch(id: selectedID)
}
```

**Instead of onChange:**
```swift
// Less idiomatic:
.onChange(of: selectedID) { _, newID in
    Task {
        data = try await api.fetch(id: newID)
    }
}
```

---

### 4. Guard Against Multiple onAppear Calls

```swift
@State private var hasInitialized = false

.onAppear {
    guard !hasInitialized else { return }
    hasInitialized = true
    
    performOneTimeSetup()
}
```

---

### 5. Use Weak Self in Closures

```swift
.onAppear {
    networkManager.fetch { [weak self] result in
        self?.data = result
    }
}
```

**Or use task to avoid closures entirely.**

---

### 6. Track Loading States

```swift
@State private var isLoading = false
@State private var error: Error?

.task {
    isLoading = true
    defer { isLoading = false }
    
    do {
        data = try await api.fetch()
    } catch {
        self.error = error
    }
}
```

---

### 7. Respect Task Cancellation

```swift
.task {
    while !Task.isCancelled {
        await doWork()
        try? await Task.sleep(for: .seconds(1))
    }
}
```

---

### 8. Use Environment scenePhase for App-Level Events

```swift
@Environment(\.scenePhase) private var scenePhase

.onChange(of: scenePhase) { oldPhase, newPhase in
    switch newPhase {
    case .active:
        resumeUpdates()
    case .inactive:
        pauseUpdates()
    case .background:
        cleanupResources()
    @unknown default:
        break
    }
}
```

---

## Summary

### Key Takeaways

**1. Two Lifecycles:**
- View struct: Short-lived (milliseconds)
- Attribute: Long-lived (until view removed)

**2. Main Lifecycle Phases:**
```
Init → Appear → Active → Disappear → Deallocate
```

**3. Lifecycle Modifiers:**
- `.onAppear` - View becomes visible
- `.onDisappear` - View removed from screen
- `.task` - Modern async lifecycle (iOS 15+)
- `.task(id:)` - Re-run when parameter changes

**4. Important Rules:**
- onAppear/onDisappear can be called multiple times
- Always clean up in onDisappear
- Use .task for async work (auto cancellation)
- Attribute persists even when view off-screen (lazy containers)

**5. State Lifecycle:**
- @State created with attribute
- @State destroyed with attribute
- Identity change = State reset

### Mental Model

```
User Action (navigation/toggle/scroll):
  ↓
Identity Created:
  → Attribute allocated
  → @State initialized
  → body runs
  ↓
View Appears:
  → onAppear called
  → task { } starts
  ↓
Active Phase:
  → body runs on state changes
  → @State persists
  ↓
View Disappears:
  → onDisappear called
  → task { } cancelled
  ↓
Identity Destroyed:
  → Attribute deallocated
  → @State lost
```

---

## Further Reading

- **WWCD 2021:** "Discover concurrency in SwiftUI"
- **WWDC 2022:** "Use SwiftUI with UIKit"
- **Apple Documentation:** [View Lifecycle](https://developer.apple.com/documentation/swiftui/view-lifecycle)
- **Swift Evolution:** [SE-0304 Structured Concurrency](https://github.com/apple/swift-evolution/blob/main/proposals/0304-structured-concurrency.md)

---

*Last Updated: December 2024*
