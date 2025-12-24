# @State in SwiftUI: Complete Guide

## Table of Contents
1. [What is @State?](#what-is-state)
2. [How @State Works](#how-state-works)
3. [Where @State is Stored](#where-state-is-stored)
4. [The Property Wrapper Mechanism](#the-property-wrapper-mechanism)
5. [Dependency Tracking](#dependency-tracking)
6. [Lifecycle and Persistence](#lifecycle-and-persistence)
7. [Common Patterns](#common-patterns)
8. [Common Mistakes](#common-mistakes)
9. [Performance Considerations](#performance-considerations)

---

## What is @State?

**@State** is a property wrapper that allows SwiftUI views to own and modify their own data while maintaining that data across view updates.

### The Core Problem @State Solves

```swift
// This DOESN'T work:
struct BrokenView: View {
    var count = 0  // ❌ Can't mutate - View structs are immutable
    
    var body: some View {
        Button("Increment") {
            count += 1  // ❌ Compiler error: Cannot assign to property
        }
    }
}
```

**Why it fails:**
1. View structs are **value types** (struct, not class)
2. SwiftUI creates and destroys view structs constantly
3. Any changes would be lost immediately
4. View protocol requires views to be immutable

### The @State Solution

```swift
struct WorkingView: View {
    @State private var count = 0  // ✓ Works!
    
    var body: some View {
        Button("Count: \(count)") {
            count += 1  // ✓ Modifies state and triggers update
        }
    }
}
```

**What @State does:**
1. Stores data **outside** the view struct (in AttributeGraph)
2. Allows mutation through special setter
3. Automatically triggers view updates when changed
4. Persists across view struct recreations

---

## How @State Works

### The Two Key Functions

**Function 1: Persistent Storage**

@State moves data from the temporary view struct into SwiftUI's persistent AttributeGraph.

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        Text("\(count)")
    }
}
```

**What happens:**

**First time view appears:**
```
1. SwiftUI creates Attribute for CounterView
2. Allocates storage inside attribute: { count: 0 }
3. Links @State property wrapper to this storage
4. View struct is temporary, storage persists
```

**Every time body runs:**
```
1. New CounterView struct created (temporary)
2. @State wrapper reconnects to same persistent storage
3. Reads count value from storage: 0
4. Uses it in body
5. View struct destroyed
6. Storage remains in attribute
```

**Function 2: Change Notification**

@State notifies SwiftUI when values change so views can update.

```swift
Button("Increment") {
    count += 1  // ← @State's setter intercepts this
}
```

**What happens:**
```
1. @State setter called with new value (1)
2. Writes to attribute storage: { count: 1 }
3. Marks attribute as "outdated"
4. Triggers SwiftUI update cycle
5. Eventually body runs with new value
```

---

## Where @State is Stored

### NOT in the View Struct

**Common Misconception:**
> "@State stores the value in the view"

**Reality:**
> "@State stores the value in the AttributeGraph node (attribute) associated with the view"

### Visual Model

```
VIEW STRUCT (Temporary - Dies Constantly)
┌─────────────────────────────────────┐
│ struct CounterView: View {          │
│   @State private var count          │  ← Property wrapper
│          ║                           │     (just a reference)
│          ║                           │
│   var body: some View { ... }       │
│ }                                    │
└─────────────────────────────────────┘
           ║
           ║ Reads/Writes through
           ║ property wrapper
           ▼
ATTRIBUTE (Persistent - Lives Until View Removed)
┌─────────────────────────────────────┐
│ CounterViewAttribute {               │
│   storage: {                         │
│     count: 5  ◄════════════════════ │ Actual storage location
│   }                                  │
│   identity: stable_id_123            │
│ }                                    │
└─────────────────────────────────────┘
```

### Proof with Example

```swift
struct TestView: View {
    @State private var count = 0
    
    var body: some View {
        let _ = print("Body runs, count = \(count)")
        let structID = ObjectIdentifier(Self.self)
        let _ = print("View struct ID: \(structID)")
        
        return VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}
```

**Output when tapping 3 times:**
```
Body runs, count = 0
View struct ID: ObjectIdentifier(0x1234...)

Body runs, count = 1
View struct ID: ObjectIdentifier(0x5678...)  ← Different struct!

Body runs, count = 2
View struct ID: ObjectIdentifier(0xABCD...)  ← Different again!

Body runs, count = 3
View struct ID: ObjectIdentifier(0xEF01...)  ← Always different!
```

**Observation:**
- View struct is **different every time** (new memory address)
- But count **persists and increments** correctly
- Therefore: count cannot be stored in the view struct

---

## The Property Wrapper Mechanism

### What @State Actually Is

@State is **syntactic sugar** for a property wrapper that wraps the `State<T>` struct.

```swift
// You write:
@State private var count = 0

// Swift expands to something like:
private var _count = State<Int>(initialValue: 0)
var count: Int {
    get { _count.wrappedValue }
    set { _count.wrappedValue = newValue }
}
```

### The State Struct (Conceptual)

```swift
// Simplified version of how State<T> works internally
@propertyWrapper
struct State<Value> {
    private var location: AttributeStorageLocation<Value>
    
    init(initialValue: Value) {
        // Register with AttributeGraph
        self.location = AttributeGraph.allocateStorage(initialValue)
    }
    
    var wrappedValue: Value {
        get {
            // Read from AttributeGraph storage
            return AttributeGraph.read(location)
        }
        set {
            // Write to AttributeGraph storage
            AttributeGraph.write(location, newValue)
            // Mark attribute as outdated
            AttributeGraph.markOutdated(location.owningAttribute)
        }
    }
    
    var projectedValue: Binding<Value> {
        // $ syntax creates a Binding
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}
```

### The Three Ways to Access @State

```swift
@State private var count = 0

// 1. Direct access (wrappedValue)
Text("\(count)")           // Reads value
count += 1                 // Writes value

// 2. Projected value (Binding)
TextField("", text: $text) // Pass binding with $

// 3. Underlying wrapper (rare)
_count                     // The State<Int> wrapper itself
```

---

## Dependency Tracking

### Automatic Dependency Creation

When you **read** @State in body, SwiftUI automatically creates a dependency.

```swift
struct MyView: View {
    @State private var count = 0
    @State private var name = "Test"
    
    var body: some View {
        VStack {
            Text("\(count)")  // ← Reads count
            // NOT reading name!
        }
    }
}
```

**Dependency Graph Created:**
```
CountAttribute ──→ BodyAttribute  ✓ (dependency created)
NameAttribute      BodyAttribute  ✗ (no dependency)
```

**Result:**
- When `count` changes → body runs ✓
- When `name` changes → body does NOT run ✓

### How Dependencies Are Captured

**Apple's Explanation (WWDC):**
> "The view is asked to create its own attributes to store its state and define its behavior. It first creates storage for the isOn state variable, and an attribute that tracks when that state variable changes. Then, the view creates a new attribute to run its body, which depends on both of these."

**Mechanism:**

```swift
var body: some View {
    // SwiftUI tracks: "Which @State properties get accessed?"
    let value = count  // ← AttributeGraph records: body depends on count
    return Text("\(value)")
}
```

During body execution, SwiftUI's AttributeGraph system records every @State read and creates edges from those state attributes to the body attribute.

### Conditional Dependencies

```swift
@State private var showDetails = false
@State private var details = "Hidden content"

var body: some View {
    VStack {
        if showDetails {
            Text(details)  // ← Only creates dependency when showDetails is true
        }
    }
}
```

**Behavior:**
- When `showDetails = false`: body doesn't depend on `details`
- When `showDetails = true`: dependency created on first read
- Dependencies can change across body executions

---

## Lifecycle and Persistence

### When @State Storage is Created

**First appearance of the view:**

```swift
NavigationLink("Go to Detail") {
    DetailView()  // ← @State storage created here
}
```

```
1. User taps link
2. SwiftUI creates DetailView struct
3. SwiftUI creates Attribute for DetailView
4. Allocates storage for all @State properties
5. Initializes with default values
6. Storage persists until view removed
```

### When @State Storage is Destroyed

**View removed from hierarchy:**

```swift
if showDetail {
    DetailView()  // @State alive
} else {
    EmptyView()   // DetailView removed → @State destroyed
}
```

```
1. showDetail changes to false
2. DetailView removed from view tree
3. AttributeGraph removes DetailView's attribute
4. All @State storage destroyed
5. Values lost forever
```

### @State Survival Across Updates

**Important:** @State survives when view struct is recreated but the **identity** remains the same.

```swift
struct ParentView: View {
    @State private var counter = 0
    
    var body: some View {
        ChildView(value: counter)  // ← New ChildView struct every update
            .id("stable")          // ← But identity is stable
    }
}
```

**What happens:**
```
1. counter changes: 0 → 1
2. ParentView.body runs
3. Creates NEW ChildView struct
4. But .id("stable") keeps identity same
5. SwiftUI reuses existing ChildView attribute
6. ChildView's @State persists
```

### Identity and @State

**Same identity = @State persists:**
```swift
ForEach(items, id: \.id) { item in
    ItemView(item: item)  // Identity: item.id
}
```

If item with id="A" moves position in array:
- View struct recreated at new position
- But id="A" remains same
- @State persists

**Different identity = @State reset:**
```swift
if condition {
    ContentView()  // Identity: position in tree
} else {
    ContentView()  // Different position = different identity!
}
```

Both ContentViews have separate @State storage because they're at different positions in the view tree.

---

## Common Patterns

### Pattern 1: Basic Local State

```swift
struct ToggleView: View {
    @State private var isOn = false
    
    var body: some View {
        Toggle("Setting", isOn: $isOn)
    }
}
```

**Use when:**
- State is private to one view
- Simple values (Bool, Int, String)
- No need to share with other views

---

### Pattern 2: Passing State Down (Binding)

```swift
struct ParentView: View {
    @State private var text = ""
    
    var body: some View {
        VStack {
            TextField("Enter text", text: $text)  // ← $ creates Binding
            ChildView(text: $text)                 // ← Pass binding down
        }
    }
}

struct ChildView: View {
    @Binding var text: String  // ← Receives binding
    
    var body: some View {
        Text("You typed: \(text)")
    }
}
```

**Pattern:**
- Parent owns @State
- Child receives @Binding
- Child can read AND modify parent's state
- Changes propagate automatically

---

### Pattern 3: Initializing with External Data

```swift
struct UserView: View {
    let user: User  // External data
    @State private var isEditing = false  // Local state
    
    var body: some View {
        if isEditing {
            TextField("Name", text: $editedName)
        } else {
            Text(user.name)
        }
    }
}
```

**Important:** You can't initialize @State from external data in the initializer!

**This DOESN'T work:**
```swift
struct UserView: View {
    let user: User
    @State private var editedName: String
    
    init(user: User) {
        self.user = user
        self._editedName = State(initialValue: user.name)  // ❌ Too late!
    }
}
```

**Why:** AttributeGraph storage already allocated before init runs.

**Solution: Use .onAppear**
```swift
struct UserView: View {
    let user: User
    @State private var editedName = ""
    
    var body: some View {
        TextField("Name", text: $editedName)
            .onAppear {
                editedName = user.name  // ✓ Update after storage created
            }
    }
}
```

**Or use wrappedValue (iOS 17+):**
```swift
struct UserView: View {
    let user: User
    @State private var editedName: String
    
    init(user: User) {
        self.user = user
        _editedName = State(wrappedValue: user.name)  // ✓ Works in iOS 17+
    }
}
```

---

### Pattern 4: Multiple Related State Properties

```swift
struct FormView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var age = 0
    
    var body: some View {
        Form {
            TextField("Name", text: $name)
            TextField("Email", text: $email)
            TextField("Age", value: $age, format: .number)
        }
    }
}
```

**When to split:**
- Different values change independently
- Want granular updates

**When to combine into object:**
```swift
@Observable
class FormData {
    var name = ""
    var email = ""
    var age = 0
}

struct FormView: View {
    @State private var formData = FormData()
    
    var body: some View {
        Form {
            TextField("Name", text: $formData.name)
            TextField("Email", text: $formData.email)
            TextField("Age", value: $formData.age, format: .number)
        }
    }
}
```

**Benefits:**
- Easier to pass around
- Single source of truth
- Can add computed properties and methods

---

### Pattern 5: State with Complex Types

```swift
struct TodoListView: View {
    @State private var todos: [Todo] = []
    
    var body: some View {
        List {
            ForEach(todos) { todo in
                Text(todo.title)
            }
            .onDelete { indexSet in
                todos.remove(atOffsets: indexSet)  // ✓ Triggers update
            }
        }
    }
}
```

**Key point:** Mutations to collection trigger updates:
```swift
// These all trigger updates:
todos.append(newTodo)       // ✓
todos.remove(at: 0)         // ✓
todos = todos.filter { ... } // ✓

// This does NOT trigger update:
todos[0].isComplete = true  // ❌ Mutates element, not array
```

**Solution for mutating elements:**
```swift
// Force array identity change:
todos[0].isComplete = true
todos = todos  // ✓ Reassign to trigger update

// Or use @Observable on Todo:
@Observable
class Todo: Identifiable {
    var isComplete = false  // ✓ Changes tracked automatically
}
```

---

## Common Mistakes

### Mistake 1: Initializing @State from Parameters

```swift
// ❌ WRONG:
struct ItemView: View {
    @State private var item: Item
    
    init(item: Item) {
        self.item = item  // ❌ This sets the view struct property, not @State storage
    }
}
```

**Why it's wrong:**
- @State storage already allocated with default value
- Assignment to `self.item` is too late
- Doesn't update AttributeGraph storage

**Fix:**
```swift
// ✓ CORRECT (iOS 14-16):
struct ItemView: View {
    let originalItem: Item
    @State private var item: Item = Item()  // Dummy default
    
    init(item: Item) {
        self.originalItem = item
    }
    
    var body: some View {
        // ...
        .onAppear {
            self.item = originalItem  // Update @State after storage created
        }
    }
}

// ✓ CORRECT (iOS 17+):
struct ItemView: View {
    @State private var item: Item
    
    init(item: Item) {
        _item = State(wrappedValue: item)  // Use underscore for wrapper
    }
}
```

---

### Mistake 2: Using @State for Shared Data

```swift
// ❌ WRONG:
struct ParentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            ChildView1(count: count)
            ChildView2(count: count)
        }
    }
}

struct ChildView1: View {
    let count: Int  // ❌ Can't modify parent's state
}
```

**Problem:** Children receive values, can't modify parent state.

**Fix with @Binding:**
```swift
// ✓ CORRECT:
struct ParentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            ChildView1(count: $count)  // Pass binding
            ChildView2(count: $count)
        }
    }
}

struct ChildView1: View {
    @Binding var count: Int  // ✓ Can modify
}
```

**Or use @Observable for complex shared state:**
```swift
@Observable
class SharedData {
    var count = 0
}

struct ParentView: View {
    @State private var data = SharedData()
    
    var body: some View {
        VStack {
            ChildView1(data: data)
            ChildView2(data: data)
        }
    }
}
```

---

### Mistake 3: Not Marking @State as Private

```swift
// ⚠️ PROBLEMATIC:
struct CounterView: View {
    @State var count = 0  // ❌ Public @State
}

// Usage:
CounterView(count: 5)  // Looks like it sets initial value, but doesn't!
```

**Problem:**
- @State initial value can't be set from outside
- Public @State suggests it can be modified externally (misleading API)
- Violates single source of truth

**Fix:**
```swift
// ✓ CORRECT:
struct CounterView: View {
    @State private var count = 0  // ✓ Private
}

// Or if needs external configuration:
struct CounterView: View {
    let initialCount: Int
    @State private var count: Int
    
    init(initialCount: Int) {
        self.initialCount = initialCount
        _count = State(wrappedValue: initialCount)
    }
}
```

---

### Mistake 4: Expecting Immediate Updates

```swift
// ❌ WRONG ASSUMPTION:
Button("Increment") {
    count += 1
    print(count)  // Might print old value!
    
    // Try to use new value immediately:
    if count == 10 {
        performAction()  // ✓ This works (count is updated)
    }
}
```

**Important:** @State updates are synchronous for reading, but view updates are asynchronous.

```swift
count += 1
print(count)  // ✓ Prints new value (1)
// But body hasn't run yet!
// Screen still shows old value (0)
```

**If you need to act after view updates:**
```swift
count += 1

DispatchQueue.main.async {
    // This runs after view update cycle
}

// Or use onChange:
.onChange(of: count) { oldValue, newValue in
    // Runs when count changes
}
```

---

### Mistake 5: Using @State for Persistent Storage

```swift
// ❌ WRONG:
struct SettingsView: View {
    @State private var username = ""  // ❌ Lost when view removed!
}
```

**Problem:** @State is destroyed when view is removed from hierarchy.

**Fix for persistence:**
```swift
// ✓ Use @AppStorage:
struct SettingsView: View {
    @AppStorage("username") private var username = ""  // ✓ Persists
}

// Or use SwiftData, Core Data, etc.
```

---

## Performance Considerations

### @State is Lightweight

**Creating @State is cheap:**
```swift
struct FastView: View {
    @State private var flag1 = false
    @State private var flag2 = false
    @State private var flag3 = false
    // ... 20 more @State properties
    
    var body: some View {
        // This is fine! @State creation is cheap
    }
}
```

**Why it's cheap:**
- Just allocates small storage in AttributeGraph
- No complex initialization
- No performance concern

---

### Minimize Dependency Scope

```swift
// ❌ BAD: Broad dependencies
struct ItemView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        VStack {
            HeaderView()  // ← Rebuilds when items changes (unnecessary!)
            List(items) { item in
                Text(item.name)
            }
        }
    }
}

// ✓ GOOD: Narrow dependencies
struct ItemView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        VStack {
            HeaderView()  // ← Static, no dependencies
            ItemList(items: items)  // ← Only this depends on items
        }
    }
}

struct ItemList: View {
    let items: [Item]
    
    var body: some View {
        List(items) { item in
            Text(item.name)
        }
    }
}
```

---

### Avoid Expensive Computed Properties

```swift
// ❌ BAD: Expensive work in body
struct ExpensiveView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        let sortedItems = items.sorted { $0.date > $1.date }  // ← Runs every body call!
        let filteredItems = sortedItems.filter { $0.isActive }
        
        return List(filteredItems) { item in
            Text(item.name)
        }
    }
}

// ✓ GOOD: Cache computed values
struct BetterView: View {
    @State private var items: [Item] = []
    @State private var cachedSortedItems: [Item] = []
    
    var body: some View {
        List(cachedSortedItems) { item in
            Text(item.name)
        }
        .onChange(of: items) { _, newItems in
            cachedSortedItems = newItems
                .sorted { $0.date > $1.date }
                .filter { $0.isActive }
        }
    }
}
```

---

## Summary

### Key Points

1. **@State stores data in AttributeGraph, not in view struct**
   - View structs are temporary
   - @State storage persists

2. **@State automatically creates dependencies**
   - Reading @State in body creates dependency
   - Changes trigger body to run

3. **@State has a lifecycle tied to view identity**
   - Created when view appears
   - Destroyed when view removed
   - Persists across view struct recreations

4. **Use @State for view-local, simple state**
   - Private to one view
   - Don't share across views (use @Binding or @Observable instead)

5. **@State triggers efficient updates**
   - Only views depending on changed state update
   - Pull-based evaluation (lazy)

---

## When to Use @State vs Other Property Wrappers

| Use Case | Property Wrapper |
|----------|-----------------|
| Private view state | `@State` |
| Shared state (simple) | `@Binding` |
| Shared state (complex) | `@Observable` + `@State` |
| External object | `@ObservedObject` or `@Bindable` |
| App-wide singleton | `@Environment` or `@EnvironmentObject` |
| Persistent storage | `@AppStorage` or `@SceneStorage` |
| Core Data | `@FetchRequest` |
| SwiftData | `@Query` |

---

## Further Reading

- **Apple Documentation:** [State | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/state)
- **WWDC Sessions:** 
  - "Data Essentials in SwiftUI" (2020)
  - "Demystify SwiftUI" (2021)
  - "Demystify SwiftUI Performance" (2024)
- **objc.io:** "Thinking in SwiftUI" book

---

*Last Updated: December 2024*
