# SwiftUI AttributeGraph: Complete Knowledge Guide

## Sources
- **Apple WWDC Video**: "Demystify SwiftUI Performance" (Instruments 26)
- **objc.io Video**: "Attribute Graph (Part 1)"
- **Book Reference**: "Thinking in SwiftUI" by objc.io

---

## Table of Contents
1. [Core Concepts](#core-concepts)
2. [The Two Trees](#the-two-trees)
3. [How AttributeGraph Works](#how-attributegraph-works)
4. [State Storage and Persistence](#state-storage-and-persistence)
5. [Dependency Tracking](#dependency-tracking)
6. [Update Mechanism](#update-mechanism)
7. [Performance Model](#performance-model)
8. [Common Patterns and Issues](#common-patterns-and-issues)

---

## Core Concepts

### What is AttributeGraph?

**Apple's Definition** (from WWDC):
> "SwiftUI's data model, the AttributeGraph defines dependencies between views, and avoids re-running your view unless necessary."

**objc.io's Clarification**:
> "Under the hood, there's no such thing as a render tree; there's only the attribute graph."

### Key Terminology

| Community Term | Apple's Official Term | What It Is |
|---------------|----------------------|------------|
| Render Tree | AttributeGraph | SwiftUI's internal persistent data structure |
| Render Tree Node | Attribute | Individual container storing view state and behavior |
| View Tree | View Tree | Temporary blueprint created by your code |

---

## The Two Trees

### View Tree (Ephemeral)

**Characteristics:**
- Created when `body` property executes
- Thrown away immediately after use
- Just Swift structs (lightweight descriptions)
- Lives for milliseconds
- Acts as a "blueprint"

**Apple Quote**:
> "View structs are recreated frequently"

**objc.io Quote**:
> "We create a value-based view tree, which serves as the blueprint for the actual views onscreen"

**Example:**
```swift
struct ContentView: View {
    var body: some View {  // ← Creates view tree when called
        VStack {
            Text("Hello")
            Button("Tap") { }
        }
    }
}
```

Every time `body` runs, a completely fresh view tree is created:
```
VStack
  ├─ Text("Hello")
  └─ Button("Tap")
```

Then immediately destroyed after SwiftUI reads it.

---

### AttributeGraph (Persistent)

**Characteristics:**
- Created once when view first appears
- Persists across all body calls
- Stores actual state (@State values)
- Updates rather than recreates
- Contains dependency information

**Apple Quote**:
> "View structs are recreated frequently, but attributes keep their identity and maintain state for the entire lifetime of the view."

**Structure:**
```
VStackAttribute {
    identity: stable_id_123
    storage: {}
    children: [TextAttribute, ButtonAttribute]
}
  ├─ TextAttribute {
        storage: { content: "Hello" }
        identity: stable_id_456
    }
  └─ ButtonAttribute {
        storage: { action: closure }
        identity: stable_id_789
    }
```

---

## How AttributeGraph Works

### Graph vs Tree

**objc.io Explanation**:
> "The difference between a tree and a graph is that a graph's dependencies can flow in any direction... The layout of the subviews depends on the configuration of the HStack, but also on the configuration of those subviews."

**Why It's a Graph:**
- Parent needs to know child sizes (child → parent dependency)
- Child needs to know parent position (parent → child dependency)
- Dependencies flow in multiple directions
- Forms a web of connections, not a simple hierarchy

**Example:**
```
HStack ←──────────┐ (needs child sizes for layout)
  ├─ Text ────────┤
  └─ Image ───────┘

HStack ────────────→ Text (provides position)
       └───────────→ Image (provides position)
```

---

### Attributes: The Core Building Blocks

**Apple's Description**:
> "When this view is first added to the view hierarchy, SwiftUI receives an object called an attribute from its parent view that stores the view struct."

**What an Attribute Contains** (from objc.io implementation):
```swift
// Conceptual structure (not actual SwiftUI code)
class Attribute<A> {
    var name: String
    var rule: (() -> A)?              // The body closure
    var _cachedValue: A?              // Stored result
    var incomingEdges: [Edge] = []    // Dependencies
    var outgoingEdges: [Edge] = []    // Dependents
}
```

**Three Types of Attributes:**

1. **Input Attributes** (@State, @Binding)
   - Store raw values
   - No rule closure
   - Source of changes

2. **Rule Attributes** (view body)
   - Store computation closure
   - Cache results
   - Depend on other attributes

3. **Derived Attributes** (computed properties, environment)
   - Transform values
   - Create dependency chains

---

## State Storage and Persistence

### Where @State Actually Lives

**Apple Quote**:
> "The view is asked to create its own attributes to store its state... It first creates storage for the isOn state variable"

**The Mechanism:**

```swift
struct CounterView: View {
    @State private var count = 0  // ← NOT stored in this struct!
    
    var body: some View {
        Text("\(count)")
    }
}
```

**What Actually Happens:**

1. **First Appearance:**
   - SwiftUI creates a CounterViewAttribute
   - Allocates storage inside that attribute: `{ count: 0 }`
   - View struct is temporary, attribute persists

2. **When body Runs:**
   - New CounterView struct created
   - @State property wrapper reads from attribute storage
   - Uses that value to create view tree
   - View struct destroyed
   - Attribute and its storage remain

3. **When count Changes:**
   - @State setter writes to attribute storage
   - Marks attribute as "outdated"
   - View struct doesn't exist at this moment
   - Storage persists in attribute

**objc.io Implementation Example:**
```swift
// Simplified version of how @State works
class Attribute<A> {
    private var _cachedValue: A?
    
    var wrappedValue: A {
        get {
            return _cachedValue!
        }
        set {
            _cachedValue = newValue
            markAsOutdated()  // Trigger update
        }
    }
}
```

---

## Dependency Tracking

### Automatic Dependency Creation

**Apple Quote**:
> "Accessing a state property from a view's body creates a dependency between the two"

**objc.io Quote**:
> "Rather than explicitly adding the edges to the graph, we want the graph to infer the dependencies on node A and B from what happens in the rule of node C."

**How It Works:**

```swift
struct MyView: View {
    @State private var count = 0
    @State private var name = "Test"
    
    var body: some View {
        Text("\(count)")  // ← Only reads count, not name
    }
}
```

**Dependency Graph Created:**
```
CountAttribute ──→ BodyAttribute
NameAttribute (no connection to body!)
```

**When count changes:** Body marked outdated ✓
**When name changes:** Body NOT marked outdated (no dependency!)

### The Edge Structure

**objc.io Implementation:**
```swift
class Edge {
    unowned var from: Attribute  // Source of dependency
    unowned var to: Attribute    // Dependent attribute
}

class Attribute {
    var incomingEdges: [Edge] = []  // What this depends on
    var outgoingEdges: [Edge] = []  // What depends on this
}
```

**Example:**
```swift
let a = graph.input(10)
let b = graph.input(20)
let c = graph.rule { a.value + b.value }
```

**Creates Graph:**
```
aAttribute
  outgoingEdges: [Edge(from: a, to: c)]
  
bAttribute
  outgoingEdges: [Edge(from: b, to: c)]
  
cAttribute
  incomingEdges: [Edge(from: a, to: c), Edge(from: b, to: c)]
  rule: { a.value + b.value }
```

---

## Update Mechanism

### Pull-Based System (Lazy Evaluation)

**objc.io Key Insight**:
> "The attribute graph is more 'pull-based' — when an input changes, it marks its dependents as potentially dirty, but nothing else happens. Then, when the system wants to use a new value, it starts reevaluating everything that's marked dirty."

### The Two-Phase Update Process

#### Phase 1: Mark as Outdated (Push)

**What Happens When @State Changes:**

```swift
@State private var count = 0

// Later...
count = 5  // ← This triggers Phase 1
```

**Step-by-Step:**

1. @State setter intercepts the write
2. CountAttribute storage updated: `{ count: 5 }`
3. CountAttribute marked as "outdated"
4. Walk through ALL outgoingEdges
5. Mark all dependent attributes as "outdated"
6. **Stop - no computation yet!**

**Apple Quote**:
> "When you change a state variable... SwiftUI doesn't immediately update your views. Instead, it creates a new transaction."

> "This transaction will mark the signal attribute for your state variable as outdated... Setting the flag happens really quickly, and no additional work happens just yet."

**Visual Timeline:**
```
Time 0: count = 5
        ├─ CountAttribute marked outdated
        ├─ Walk edges
        └─ BodyAttribute marked outdated
        
Time 1-100: Nothing happens (both remain outdated)
```

#### Phase 2: Evaluate (Pull)

**What Happens When SwiftUI Needs to Render:**

**Apple Quote**:
> "After running any other transactions, SwiftUI now needs to figure out what to draw to the screen for this frame. But it can't access that information because it's marked as outdated. So SwiftUI must update all the dependencies of this information"

**Step-by-Step:**

1. SwiftUI prepares next frame
2. Checks BodyAttribute: "Is this outdated?"
3. Yes → need to evaluate
4. Check dependencies: CountAttribute also outdated
5. Evaluate CountAttribute first (read value: 5)
6. Now evaluate BodyAttribute:
   - Execute `body` closure (rule)
   - Create new view tree
   - Cache result
   - Mark as clean
7. Use result to update display

**objc.io Implementation:**
```swift
var wrappedValue: A {
    get {
        if _cachedValue == nil, let rule {
            _cachedValue = rule()  // ← Execute body here!
        }
        return _cachedValue!
    }
}
```

**Key Point:** Body only executes when someone **pulls** the value (needs to render).

---

### Transaction System

**Apple's Explanation:**
> "When you change a state variable, SwiftUI doesn't immediately update your views. Instead, it creates a new transaction. A transaction represents a change to the SwiftUI view hierarchy that needs to be made before the next frame."

**Transaction Flow:**
```
State Change → Create Transaction → Mark Outdated
                                         ↓
                                    Queue for next frame
                                         ↓
                                    Frame deadline approaches
                                         ↓
                                    Process transaction
                                         ↓
                                    Evaluate outdated attributes
                                         ↓
                                    Update display
```

---

## Performance Model

### The Render Loop (Apple's Diagram Explanation)

**Normal Frame (No Hitch):**
```
Frame N:
├─ Handle Events (touch, gestures)
├─ Update UI (run body for changed views)
├─ Hand off to renderer
└─ Frame deadline ✓

Frame N+1:
├─ System renders previous frame
├─ Display on screen
└─ New frame begins
```

**Frame With Hitch (Long View Body):**
```
Frame N:
├─ Handle Events
├─ Update UI (body takes too long!) ⚠️
├─ Miss frame deadline ✗
└─ Can't hand off to renderer

Frame N+1:
├─ Still finishing UI update
├─ Old frame remains visible (hitch!)
└─ User sees stutter

Frame N+2:
├─ Finally hand off to renderer
└─ New content appears (late)
```

**Apple Quote**:
> "Everything here is working just as it should. Updates complete before their corresponding frame deadlines... When UI updates run past the frame deadline, this causes the next update to be delayed by a frame... We call a frame that stays visible on screen for too long, delaying future frames, a hitch."

---

### What Makes Body Run?

**Apple's Description:**

1. **Outdated attribute accessed**
   - SwiftUI needs to render
   - Checks attribute status
   - If outdated → run body

2. **Dependencies changed**
   - Only runs if dependencies actually changed
   - Smart skipping when values unchanged

**Example from WWDC:**
```swift
struct OnOffView: View {
    @State private var isOn = false
    
    var body: some View {
        Text(isOn ? "On" : "Off")
    }
}
```

**Timeline:**
1. isOn changes: false → true
2. Mark attributes outdated
3. Next frame needs display
4. Check: BodyAttribute outdated? Yes
5. Execute body → creates Text("On")
6. Cache result
7. Display

---

### What Causes Performance Issues?

#### 1. Long View Body Updates

**Problem:**
```swift
var body: some View {
    let distance = expensiveFormatting()  // ← 5ms each time!
    Text(distance)
}
```

**Apple's Example from WWDC:**

They showed LandmarkListItemView with expensive formatters:
```swift
var distance: String {
    let formatter = MeasurementFormatter()  // ← Expensive!
    let numberFormatter = NumberFormatter() // ← Expensive!
    return formatter.string(from: measurement)
}

var body: some View {
    Text(distance)  // ← Runs formatter every body call
}
```

**Solution:**
```swift
// In model class:
class LocationFinder {
    let formatter = MeasurementFormatter()  // ← Create once
    var cachedDistances: [String] = []      // ← Cache results
    
    func updateDistances() {
        // Pre-calculate all distances
        cachedDistances = landmarks.map { 
            formatter.string(from: $0.distance) 
        }
    }
}

// In view:
var body: some View {
    Text(locationFinder.cachedDistances[index])  // ← Fast!
}
```

#### 2. Unnecessary View Body Updates

**Problem:**
```swift
class ModelData: ObservableObject {
    @Published var favorites: [Landmark] = []
    
    func isFavorite(_ landmark: Landmark) -> Bool {
        favorites.contains(landmark)  // ← Accesses whole array
    }
}

struct ItemView: View {
    var landmark: Landmark
    @ObservedObject var modelData: ModelData
    
    var body: some View {
        Button {
            modelData.toggleFavorite(landmark)
        } label: {
            Image(systemName: modelData.isFavorite(landmark) ? "heart.fill" : "heart")
        }
    }
}
```

**Issue:** Every item view depends on entire favorites array!

**Dependency Graph:**
```
FavoritesArray ──→ ItemView1.body
               ├─→ ItemView2.body
               ├─→ ItemView3.body
               └─→ ItemView4.body (and 50 more!)
```

When ANY favorite changes → ALL item views marked outdated → ALL bodies run!

**Apple Quote from WWDC:**
> "Because each view accessed the favorites array, even though it was indirectly, the @Observable macro has created a dependency for each view on the whole array of favorites... But that's not ideal, because the only view I actually changed was view number three."

**Solution:**
```swift
@Observable
class LandmarkViewModel {
    var isFavorite: Bool = false  // ← Per-landmark state
}

class ModelData {
    var viewModels: [UUID: LandmarkViewModel] = [:]
}

struct ItemView: View {
    var viewModel: LandmarkViewModel  // ← Only depends on own model
    
    var body: some View {
        Button {
            viewModel.isFavorite.toggle()
        } label: {
            Image(systemName: viewModel.isFavorite ? "heart.fill" : "heart")
        }
    }
}
```

**New Dependency Graph:**
```
ViewModel1.isFavorite ──→ ItemView1.body only
ViewModel2.isFavorite ──→ ItemView2.body only
ViewModel3.isFavorite ──→ ItemView3.body only
```

Now changing one favorite only updates one view!

---

### Environment Dependencies

**Apple's Warning:**

> "Even in cases where a view's body doesn't need to run as a result of an environment update, there is still a cost associated with checking for updates to the value of interest to the view. The time spent can add up quickly if your app has a lot of views reading from the environment."

**Problem Pattern:**
```swift
struct MyView: View {
    @Environment(\.currentTime) var time  // ← Updates every second!
    
    var body: some View {
        Text("Hello")  // ← Doesn't even use time
    }
}
```

**What Happens:**
1. currentTime updates (every second)
2. ALL views reading environment get checked
3. Even if they don't use currentTime
4. Checking is fast, but adds up with many views

**Guideline:**
> "That's why it's important to avoid storing values that update really often, such as geometry values or timers, in the environment."

---

## Common Patterns and Issues

### Pattern 1: State Changes Don't Trigger Update

**Problem:**
```swift
struct MyView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        List(items) { item in
            Text(item.name)
        }
        .onAppear {
            items[0].name = "Updated"  // ← Body doesn't run!
        }
    }
}
```

**Why:** Mutating array contents doesn't change the array identity. AttributeGraph doesn't see change.

**Solution:**
```swift
items[0].name = "Updated"
items = items  // ← Force array reassignment, or use @Observable on Item
```

---

### Pattern 2: Parent Rebuild Triggers Child Rebuild

**Issue:**
```swift
struct ParentView: View {
    @State private var count = 0
    
    var body: some View {
        ChildView()  // ← Rebuilds when count changes
    }
}

struct ChildView: View {
    var body: some View {
        print("Child body ran")  // ← Prints every time parent updates!
        return Text("Static")
    }
}
```

**Why:** Parent's body creates new ChildView struct → SwiftUI calls child's body

**Not Always a Problem:**
- ChildView struct creation is cheap
- If body is fast, no performance issue

**When It Matters:**
- Child has expensive body computation
- Child has many subviews

**Solution (if needed):**
```swift
struct ChildView: View, Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        true  // ← Never different, skip body
    }
    
    var body: some View {
        Text("Static")
    }
}

// In parent:
ChildView().equatable()  // ← Apply equatable modifier
```

---

### Pattern 3: Gestures vs Animations

**Gestures (Continuous Updates):**
```swift
@State private var offset: CGFloat = 0

var body: some View {
    Circle()
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = value.translation.height  // ← Changes constantly!
                }
        )
}
```

**What Happens:**
- offset changes 60-120 times per second during drag
- body runs 60-120 times per second
- Each run creates new view tree
- Attribute updated each time
- Render tree updated each time

**This is fine!** Each body call is cheap (just creating Circle struct).

**Animations (One Update):**
```swift
@State private var isExpanded = false

var body: some View {
    Circle()
        .scaleEffect(isExpanded ? 2.0 : 1.0)
        .animation(.spring, value: isExpanded)
}
```

**What Happens:**
- isExpanded changes once: false → true
- body runs ONCE
- Creates Circle with scale 2.0
- Animation modifier tells Core Animation: "interpolate from 1.0 to 2.0"
- Core Animation updates GPU at 120fps
- body does NOT run during animation

**Key Difference:**
- Gestures: State changes → body runs every frame
- Animations: State changes once → Core Animation interpolates

---

### Pattern 4: Identity Issues

**Problem:**
```swift
ForEach(landmarks) { landmark in
    LandmarkRow(landmark: landmark)
}

// When landmarks array updated:
// SwiftUI can't tell which rows are same/different
```

**Apple's Explanation:**
Attributes have **identity**. When view appears, attribute created with stable ID. If SwiftUI can't match old view to new view, it destroys old attribute (loses state!) and creates new one.

**Solution:**
```swift
ForEach(landmarks, id: \.id) { landmark in
    LandmarkRow(landmark: landmark)
}

// Or make Landmark conform to Identifiable:
struct Landmark: Identifiable {
    let id: UUID
    // ...
}
```

---

## Key Takeaways

### Mental Model Summary

1. **Two Structures:**
   - View Tree: Temporary blueprint (your code)
   - AttributeGraph: Persistent storage (SwiftUI's internals)

2. **State Storage:**
   - @State values live in attributes, NOT in view structs
   - View structs die and regenerate constantly
   - Attributes persist until view removed

3. **Update Flow:**
   - Phase 1: Mark outdated (fast, happens immediately)
   - Phase 2: Evaluate (lazy, happens when needed)

4. **Dependencies:**
   - Created automatically by reading values
   - Form a graph (multi-directional)
   - Determine what updates when

5. **Performance:**
   - Keep body fast (avoid expensive work)
   - Minimize unnecessary dependencies
   - Use granular state (not large shared objects)

---

## Best Practices from Apple

From WWDC "Demystify SwiftUI Performance":

> "Ensure your view bodies update quickly and only when needed to achieve great SwiftUI performance."

**Quick Bodies:**
- Move expensive work out of body
- Pre-calculate and cache values
- Use formatters efficiently

**Only When Needed:**
- Design granular state models
- Avoid dependencies on frequently-changing values
- Don't put timers/geometry in environment

**Use Instruments:**
- Profile early and often
- Look for long view body updates (red/orange)
- Check Cause & Effect Graph for unnecessary updates

---

## Further Reading

- **WWDC Session:** "Demystify SwiftUI Performance" (2024)
- **objc.io Book:** "Thinking in SwiftUI" (2023)
- **objc.io Videos:** Attribute Graph series
- **Research Paper:** "A System for Efficient and Flexible One-Way Constraint Evaluation in C++" (inspiration for AttributeGraph)

---

## Glossary

**Attribute:** SwiftUI's internal persistent container for a view (Apple's term for "node")

**AttributeGraph:** SwiftUI's internal system for managing view state and dependencies (Apple's term for "render tree")

**View Tree:** Temporary hierarchy of view structs created by your code

**Body:** Computed property that creates view tree; contains the "rule" for a view

**Transaction:** Scheduled change to view hierarchy, processed before next frame

**Outdated:** State of an attribute marked as needing re-evaluation

**Edge:** Dependency connection between attributes

**Pull-Based:** System where work happens lazily when result is requested

**Mark Dirty:** Setting an attribute's outdated flag (fast operation)

**Evaluate:** Actually running body closure to compute new value (potentially slow)

---

*Document compiled from Apple WWDC 2024 and objc.io materials - December 2024*
