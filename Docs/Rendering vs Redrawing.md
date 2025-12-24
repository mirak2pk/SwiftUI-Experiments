# Redrawing vs Rendering in SwiftUI

## Table of Contents
1. [Core Definitions](#core-definitions)
2. [The Complete Update Pipeline](#the-complete-update-pipeline)
3. [Redrawing (View Tree Recreation)](#redrawing-view-tree-recreation)
4. [Rendering (Display Updates)](#rendering-display-updates)
5. [The Relationship Between Them](#the-relationship-between-them)
6. [Performance Implications](#performance-implications)
7. [Common Misconceptions](#common-misconceptions)
8. [Practical Examples](#practical-examples)

---

## Core Definitions

### Redrawing

**Redrawing** = Executing the `body` property to create a fresh view tree.

```swift
struct MyView: View {
    @State private var count = 0
    
    var body: some View {  // ← This executing = "redrawing"
        Text("Count: \(count)")
    }
}
```

**Characteristics:**
- Your code runs
- Creates new Swift structs
- View tree (blueprint) is regenerated
- Happens in Swift code on CPU
- Lightweight operation

**Apple's Term:** "View body update" or "body evaluation"

---

### Rendering

**Rendering** = Updating the actual pixels on screen through the GPU.

**Characteristics:**
- GPU work
- Pixel composition
- Visual output changes
- Happens in Metal/Core Animation layer
- Can be expensive

**Apple's Term:** "Display update" or "frame rendering"

---

## The Complete Update Pipeline

### The Full Journey: State Change → Pixels

```
┌─────────────────────────────────────────────────────────────┐
│ 1. STATE CHANGE                                              │
│    @State var count = 0                                     │
│    count += 1  ← User action                                │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. MARK OUTDATED (AttributeGraph)                           │
│    - Mark count attribute outdated                          │
│    - Walk dependency edges                                  │
│    - Mark dependent attributes outdated                     │
│    - No computation yet!                                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. TRANSACTION SCHEDULED                                     │
│    - SwiftUI creates transaction                            │
│    - Queued for next frame deadline                         │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. REDRAWING (Pull Phase)                                   │
│    - Frame deadline approaching                             │
│    - Execute body property                                  │
│    - Create new view tree (Swift structs)                   │
│    - Your code runs here                                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. COMPARE & UPDATE ATTRIBUTEGRAPH                          │
│    - Compare new view tree to existing AttributeGraph       │
│    - Identify differences                                   │
│    - Update AttributeGraph nodes                            │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. LAYOUT                                                    │
│    - Calculate positions and sizes                          │
│    - Parent proposes space                                  │
│    - Child returns size                                     │
│    - Parent places child                                    │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. RENDERING (Core Animation + GPU)                         │
│    - Build layer tree                                       │
│    - Composite layers                                       │
│    - Rasterize (convert to pixels)                         │
│    - Send to GPU                                            │
│    - Display on screen                                      │
└─────────────────────────────────────────────────────────────┘
```

**Key Insight:** Redrawing (step 4) and Rendering (step 7) are **separate steps** with different performance characteristics.

---

## Redrawing (View Tree Recreation)

### What Happens During a Redraw

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {  // ← THIS FUNCTION EXECUTING = REDRAW
        print("Body executed")  // ← Proves body ran
        
        return VStack {
            Text("Count: \(count)")
            Button("Increment") { count += 1 }
        }
    }
}
```

**When you tap the button:**

```
1. count changes: 0 → 1
2. AttributeGraph marks body outdated
3. SwiftUI pulls new value (executes body)
4. "Body executed" prints to console
5. New view tree created:
   VStack (new struct instance)
     ├─ Text("Count: 1") (new struct instance)
     └─ Button(...) (new struct instance)
6. Old view tree discarded
```

### View Tree = Temporary Blueprint

**Important:** The view tree created by `body` is **ephemeral** (temporary).

```swift
var body: some View {
    let vstack = VStack {  // New VStack struct created
        Text("Hello")      // New Text struct created
    }
    // vstack and Text are immediately garbage collected after this function returns
    return vstack
}
```

**Lifecycle:**
```
body starts → Create structs → body ends → Structs destroyed
(milliseconds total)
```

### When Body Gets Called (Redraw Triggers)

**1. @State changes:**
```swift
@State private var count = 0
count += 1  // ← Triggers body
```

**2. @Binding changes from parent:**
```swift
struct Child: View {
    @Binding var value: Int
    
    var body: some View {
        Text("\(value)")  // ← Redraws when parent changes value
    }
}
```

**3. @Observable/@ObservedObject property changes:**
```swift
@Observable
class Model {
    var count = 0  // ← Changing this triggers body
}

struct MyView: View {
    let model: Model
    
    var body: some View {
        Text("\(model.count)")  // ← Redraws when model.count changes
    }
}
```

**4. Parent view redraws:**
```swift
struct Parent: View {
    @State private var count = 0
    
    var body: some View {
        Child()  // ← Child's body called even though it has no @State
    }
}
```

**Why?** Parent's body creates new `Child()` struct → SwiftUI calls child's body to see what it produces.

### Redrawing is Cheap

**Apple's Guidance (from objc.io "Thinking in SwiftUI"):**
> "View structs are recreated frequently, but attributes keep their identity and maintain state for the entire lifetime of the view."

**Why it's cheap:**
- Just creating small Swift structs (value types)
- No memory allocation on heap
- No complex initialization
- Compiler optimizes struct creation
- Typically microseconds per view

**Example:**
```swift
struct SimpleView: View {
    var body: some View {
        VStack {            // ~1 nanosecond
            Text("Hello")   // ~1 nanosecond
            Text("World")   // ~1 nanosecond
        }
    }
}
// Total: ~3 nanoseconds to create view tree
```

Even complex view hierarchies with 100+ views take microseconds to redraw.

---

## Rendering (Display Updates)

### What Happens During Rendering

**After redraw completes:**

```
1. SwiftUI has new view tree
2. Compares to AttributeGraph
3. Identifies visual differences
4. Tells Core Animation what changed
5. Core Animation builds/updates layer tree
6. Compositor combines layers
7. Rasterization (convert shapes/text to pixels)
8. GPU processes
9. Pixels sent to display
10. Screen updates
```

### Rendering is Expensive

**Types of rendering work (ordered by cost):**

**1. Simple updates (cheap):**
- Color changes
- Opacity changes
- Position changes (translation)

**2. Moderate updates:**
- Size changes (may need re-layout)
- Rotation/scale transforms
- Shadow rendering

**3. Expensive updates:**
- Blur effects (`.blur()`)
- Complex gradients
- Masks and clipping
- Drawing custom shapes
- Image processing

**4. Very expensive:**
- Creating new layers
- Structural changes to layer tree
- Off-screen rendering
- Complex animations with many simultaneous changes

### The 120Hz Display Reality

**Your iPhone ProMotion Display:**
- Refreshes 120 times per second (120Hz)
- Every 8.33 milliseconds = new frame
- Budget per frame: ~8ms for all work

**Frame Budget Breakdown:**
```
8.33ms total budget:
  ├─ 3-4ms: Your app's work (events, body, layout)
  └─ 4-5ms: System rendering (Core Animation, GPU)
```

**Critical:** If your work takes >3-4ms, you risk missing frame deadline → hitch.

---

## The Relationship Between Them

### Redrawing ≠ Rendering

**Key Principle:** Just because body runs doesn't mean screen updates!

**Example 1: Redraw Without Render**

```swift
struct NoRenderView: View {
    @State private var timestamp = Date()
    
    var body: some View {
        let _ = print("Body ran at \(timestamp)")
        
        Text("Static content")  // ← Always same output
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    timestamp = Date()  // ← Changes every second
                }
            }
    }
}
```

**What happens:**
```
Second 0: Body runs → Text("Static content")
Second 1: Body runs → Text("Static content") ← Same!
Second 2: Body runs → Text("Static content") ← Same!
```

**Result:**
- Body runs every second (redraw) ✓
- Screen never updates (no rendering) ✓

**Why?** SwiftUI compares view trees, sees `Text("Static content")` is identical, skips rendering.

---

**Example 2: Animation - One Redraw, Many Renders**

```swift
struct AnimatedView: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Circle()
            .scaleEffect(scale)
            .animation(.linear(duration: 2), value: scale)
            .onAppear { scale = 2.0 }
    }
}
```

**Timeline:**
```
Time 0ms: 
  - scale changes: 1.0 → 2.0
  - Body runs ONCE
  - Creates: Circle().scaleEffect(2.0)
  - Animation modifier: "Animate from 1.0 to 2.0 over 2 seconds"
  
Time 8ms:   Render frame (scale: 1.05) ← Body NOT called
Time 16ms:  Render frame (scale: 1.10) ← Body NOT called
Time 24ms:  Render frame (scale: 1.15) ← Body NOT called
...
Time 2000ms: Render frame (scale: 2.0)  ← Body NOT called

Total: 1 redraw, 240 renders (2 seconds × 120fps)
```

**Key Insight:** Animation modifier tells Core Animation to interpolate. Your body doesn't run again!

---

**Example 3: Gesture - Many Redraws, Many Renders**

```swift
struct DragView: View {
    @State private var offset: CGFloat = 0
    
    var body: some View {
        Circle()
            .offset(y: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation.height
                    }
            )
    }
}
```

**During drag:**
```
Time 0ms:   offset = 0    → Body runs → Render
Time 8ms:   offset = 5    → Body runs → Render
Time 16ms:  offset = 12   → Body runs → Render
Time 24ms:  offset = 20   → Body runs → Render
...
```

**Result:** Body runs AND renders on every frame (120 times/second during drag).

**Why?** You're changing state on every frame. No animation modifier. SwiftUI must redraw to get new offset value.

---

### The Optimization: Diffing

**SwiftUI's Smart Behavior:**

After body creates new view tree, SwiftUI performs **structural diffing**:

```
Old View Tree:          New View Tree:
VStack                  VStack              ← Same
  ├─ Text("Count: 5")     ├─ Text("Count: 6")   ← Different!
  └─ Button(...)          └─ Button(...)        ← Same
```

**SwiftUI only renders the changed parts:**
```
1. VStack: No change → Skip rendering
2. Text: Content changed → Re-render this text
3. Button: No change → Skip rendering
```

**Efficiency:** Only the Text gets new pixels, not the entire VStack.

---

## Performance Implications

### Redrawing Performance

**Redrawing is usually not the bottleneck because:**

1. **View struct creation is cheap**
   ```swift
   // This is microseconds:
   VStack {
       Text("Hello")
       Text("World")
   }
   ```

2. **Body execution is typically fast**
   - Unless you do expensive work inside

**When redrawing becomes slow:**

```swift
// ❌ BAD: Expensive work in body
var body: some View {
    let formatted = expensiveFormatter.string(from: data)  // ← 5ms!
    let sorted = items.sorted()  // ← 10ms for 1000 items!
    
    return Text(formatted)
}
```

**Apple's WWDC Example (Landmarks App):**

```swift
var distance: String {
    let formatter = MeasurementFormatter()  // ← Creating formatter: 1ms
    let numberFormatter = NumberFormatter() // ← Creating formatter: 1ms
    return formatter.string(from: measurement)  // ← Formatting: 1ms
}

var body: some View {
    Text(distance)  // ← Calls distance property → 3ms wasted
}
```

**Problem:** With 50 landmark views, that's 150ms just in body execution!

**Solution:** Pre-calculate and cache:

```swift
class LocationManager {
    let formatter = MeasurementFormatter()  // ← Create once
    var cachedDistances: [String] = []      // ← Cache results
    
    func updateDistances() {
        cachedDistances = landmarks.map { formatter.string(from: $0.distance) }
    }
}

var body: some View {
    Text(cachedDistances[index])  // ← Fast: ~0.001ms
}
```

---

### Rendering Performance

**Rendering is usually the bottleneck because:**

1. **GPU work is expensive**
   - Rasterization
   - Compositing
   - Applying effects

2. **Complex views cost more**
   ```swift
   // Cheap to render:
   Text("Hello")
   
   // Expensive to render:
   Text("Hello")
       .blur(radius: 10)        // ← Requires multiple GPU passes
       .shadow(radius: 20)       // ← Off-screen rendering
       .mask(ComplexShape())     // ← Additional compositing
   ```

3. **Many simultaneous animations**
   ```swift
   // 50 views animating = 50× rendering work per frame
   ForEach(items) { item in
       ItemView(item: item)
           .scaleEffect(animatingScale)
   }
   ```

**Apple's Render Loop Diagram (from WWDC):**

**Without Hitch:**
```
Frame N:   [Events][UI Update][Layout] → Hand off → [Render] → Display
           |←    3ms     →|                           4ms
           Total: 7ms ✓ (within 8.33ms budget)
```

**With Hitch (Expensive Rendering):**
```
Frame N:   [Events][UI Update][Layout] → [Render......] (too long!)
           |←    3ms     →|              7ms ✗
           Total: 10ms (missed deadline)

Frame N+1: [Still rendering...] → Display
           Previous frame stays visible (hitch!)
```

---

### The 60fps vs 120fps Reality

**Display Refresh Rates:**
- Standard displays: 60Hz (16.67ms per frame)
- ProMotion displays: 120Hz (8.33ms per frame)

**Budget Implications:**

**At 60Hz:**
```
16.67ms budget
  ├─ 6-8ms: Your app
  └─ 8-10ms: System rendering
```

**At 120Hz:**
```
8.33ms budget
  ├─ 3-4ms: Your app
  └─ 4-5ms: System rendering
```

**Takeaway:** ProMotion is HARDER to hit! Half the time budget.

---

## Common Misconceptions

### Misconception 1: "My view redraws 120 times per second"

**Reality:** Only if you're changing state 120 times per second (like during gesture tracking).

**Example:**
```swift
struct MyView: View {
    @State private var count = 0
    
    var body: some View {
        Text("\(count)")
    }
}
```

If count never changes:
- Body runs: 1 time (on appear)
- Screen renders: 1 time
- Not 120 times per second!

---

### Misconception 2: "Animations cause body to run on every frame"

**Reality:** Animations run in Core Animation. Body runs once.

```swift
@State private var isExpanded = false

var body: some View {
    Rectangle()
        .frame(height: isExpanded ? 300 : 100)
        .animation(.spring, value: isExpanded)
}
```

**When isExpanded toggles:**
- Body runs: 1 time ✓
- Core Animation interpolates: 120 frames
- Body does NOT run 120 times ✓

---

### Misconception 3: "More redraws = worse performance"

**Reality:** Redraws are cheap. Expensive rendering or expensive body computations are the problem.

**Fast despite many redraws:**
```swift
var body: some View {
    Text("Hello")  // ← Cheap struct creation
}
// Can redraw 1000 times/second, still performant
```

**Slow despite few redraws:**
```swift
var body: some View {
    expensiveBlurEffect()  // ← Expensive GPU work
}
// Even 1 redraw causes lag
```

---

### Misconception 4: "SwiftUI is slow because it redraws everything"

**Reality:** SwiftUI only redraws views with changed dependencies.

```swift
struct Parent: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            CounterView(count: count)  // ← Redraws when count changes
            StaticView()               // ← Does NOT redraw
        }
    }
}
```

SwiftUI's dependency tracking ensures StaticView's body never runs when count changes.

---

### Misconception 5: "I need to optimize redraws"

**Reality:** Usually optimize rendering, not redraws.

**Typical performance issue:**
```swift
// Not this (redraw optimization):
var body: some View {
    MyView().equatable()  // ← Rarely needed
}

// Fix this (rendering optimization):
var body: some View {
    Text("Heavy")
        .blur(radius: 50)      // ← Remove/reduce expensive effects
        .shadow(radius: 100)    // ← These kill performance
}
```

---

## Practical Examples

### Example 1: Debugging Redraws

**Add logging to see when body runs:**

```swift
struct MyView: View {
    @State private var count = 0
    
    var body: some View {
        let _ = Self._printChanges()  // ← Prints what caused redraw
        let _ = print("Body executed at \(Date())")
        
        return Text("\(count)")
    }
}
```

**Output:**
```
MyView: @self, @identity, _count changed.
Body executed at 2024-12-24 10:30:15
```

---

### Example 2: Avoiding Unnecessary Redraws

**Problem: Child redraws unnecessarily**

```swift
struct Parent: View {
    @State private var counter = 0
    
    var body: some View {
        VStack {
            Text("\(counter)")
            ExpensiveChild()  // ← Redraws even though it doesn't use counter
        }
    }
}
```

**Solution: Extract to separate view with stable identity**

```swift
struct Parent: View {
    @State private var counter = 0
    
    var body: some View {
        VStack {
            CounterText(counter: counter)  // ← Only this redraws
            ExpensiveChild()               // ← Stable, doesn't redraw
        }
    }
}

struct CounterText: View {
    let counter: Int
    
    var body: some View {
        Text("\(counter)")
    }
}

struct ExpensiveChild: View {
    var body: some View {
        // Complex view hierarchy
    }
}
```

---

### Example 3: Gesture vs Animation Performance

**Gesture (continuous redraws):**

```swift
@GestureState private var dragOffset: CGFloat = 0

var body: some View {
    Circle()
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation.height
                }
        )
}
```

**Performance:**
- Redraws: ~120/second during drag
- Renders: ~120/second during drag
- Body is simple → No problem!

**Animation (one redraw):**

```swift
@State private var offset: CGFloat = 0

var body: some View {
    Circle()
        .offset(y: offset)
        .animation(.spring, value: offset)
        .onAppear { offset = 100 }
}
```

**Performance:**
- Redraws: 1 time (when offset changes)
- Renders: ~120 frames (spring animation)
- Body doesn't run during animation → Efficient!

---

### Example 4: List Performance

**Problem: All rows redraw when one item changes**

```swift
@Observable
class ItemStore {
    var items: [Item] = []
}

struct ListView: View {
    let store: ItemStore
    
    var body: some View {
        List(store.items) { item in
            RowView(item: item)  // ← All rows depend on store.items!
        }
    }
}
```

**When any item changes → All rows redraw!**

**Solution: Granular dependencies**

```swift
@Observable
class Item: Identifiable {
    var title: String
    var isComplete: Bool
}

struct ListView: View {
    let items: [Item]  // ← Just array reference, not @Observable
    
    var body: some View {
        List(items) { item in
            RowView(item: item)  // ← Each row depends only on its item
        }
    }
}

struct RowView: View {
    let item: Item  // ← @Observable, creates dependency
    
    var body: some View {
        Text(item.title)  // ← Only this row redraws when item.title changes
    }
}
```

**Result:** Changing one item only redraws that row!

---

### Example 5: Measuring Body Performance

**Use Instruments to see long view body updates:**

1. Profile app with SwiftUI template
2. Look at "Long View Body Updates" lane
3. Red/orange = body taking too long (>1ms typically)

**Or add timing manually:**

```swift
var body: some View {
    let start = CFAbsoluteTimeGetCurrent()
    
    let content = VStack {
        // Your view code
    }
    
    let duration = CFAbsoluteTimeGetCurrent() - start
    print("Body took: \(duration * 1000)ms")
    
    return content
}
```

**Target:** Body should complete in <1ms for smooth 120fps.

---

## Summary

### Key Takeaways

| Aspect | Redrawing | Rendering |
|--------|-----------|-----------|
| **What** | Executing body property | Drawing pixels on screen |
| **Where** | Swift code (CPU) | Core Animation + GPU |
| **When** | State changes | After redraw + layout |
| **Cost** | Usually cheap (~microseconds) | Can be expensive (milliseconds) |
| **Frequency** | When dependencies change | 60-120fps during animations |
| **Optimization** | Avoid expensive body computation | Avoid expensive visual effects |

### Mental Model

```
State Change
    ↓
Redraw (body runs) ← Your code, cheap
    ↓
Compare view trees
    ↓
Update AttributeGraph
    ↓
Layout calculation
    ↓
Render (GPU work) ← System work, can be expensive
    ↓
Display update
```

### Performance Guidelines

**For Redraws:**
1. Keep body fast (no expensive computation)
2. Pre-calculate and cache expensive values
3. Don't worry about redraw frequency itself

**For Renders:**
1. Minimize expensive effects (blur, shadow)
2. Use animations instead of continuous state changes when possible
3. Profile with Instruments to find rendering bottlenecks

### When to Optimize What

**Optimize Redraws if:**
- Instruments shows long view body updates (red/orange)
- Body contains expensive computation
- Creating formatters/objects in body

**Optimize Renders if:**
- Animations are janky
- Scrolling is stuttering
- Instruments shows long frame times
- Using many expensive visual effects

---

## Further Reading

- **WWDC 2024:** "Demystify SwiftUI Performance"
- **WWDC 2021:** "Demystify SwiftUI" 
- **Apple Article:** "Understanding hitches in your app"
- **objc.io:** "Thinking in SwiftUI" - View Trees chapter

---

*Last Updated: December 2024*
