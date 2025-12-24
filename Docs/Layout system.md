# SwiftUI Layout System: Complete Guide

## Table of Contents
1. [Overview](#overview)
2. [The Three-Step Layout Process](#the-three-step-layout-process)
3. [How Layout Works: Parent and Child Negotiation](#how-layout-works-parent-and-child-negotiation)
4. [Layout Priority and Flexibility](#layout-priority-and-flexibility)
5. [Common Layout Modifiers](#common-layout-modifiers)
6. [Stack Layouts (HStack, VStack, ZStack)](#stack-layouts-hstack-vstack-zstack)
7. [Frame Modifiers Deep Dive](#frame-modifiers-deep-dive)
8. [Layout Debugging](#layout-debugging)
9. [Common Layout Patterns](#common-layout-patterns)
10. [Common Layout Problems](#common-layout-problems)

---

## Overview

### What is Layout?

**Layout** is the process of determining the **position and size** of every view in your app.

SwiftUI's layout system is fundamentally different from UIKit:

**UIKit (Imperative):**
```
You tell views: "Be at position (x: 100, y: 200) with size (width: 300, height: 50)"
```

**SwiftUI (Declarative):**
```
Parent and child negotiate:
Parent: "I have this much space available"
Child: "Given that space, I need this much"
Parent: "Okay, I'll place you here"
```

### Key Characteristics

1. **Negotiation-based:** Parent proposes, child decides
2. **Bottom-up sizing:** Child determines its size based on content
3. **Top-down placement:** Parent decides where to place child
4. **Single-pass:** Layout happens in one traversal (usually)
5. **View-centric:** Each view type has its own layout behavior

---

## The Three-Step Layout Process

### The Layout Algorithm

Every layout operation follows this three-step dance:

```
┌─────────────────────────────────────────────────────────────┐
│ STEP 1: PARENT PROPOSES SIZE                                │
│                                                              │
│ Parent: "You have up to (width: 300, height: 400)"         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 2: CHILD CHOOSES SIZE                                  │
│                                                              │
│ Child looks at:                                             │
│   - Proposed size from parent                               │
│   - Its own content                                         │
│   - Its own layout rules                                    │
│                                                              │
│ Child: "I need (width: 200, height: 50)"                   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ STEP 3: PARENT PLACES CHILD                                 │
│                                                              │
│ Parent: "I'll put you at (x: 50, y: 175)"                  │
│                                                              │
│ Child is now positioned in parent's coordinate space       │
└─────────────────────────────────────────────────────────────┘
```

### Apple's Official Description

From WWDC and SwiftUI documentation:

> "SwiftUI's layout system uses a three-step process:
> 1. **Parent proposes a size** to the child
> 2. **Child chooses its own size** based on the proposal and its content
> 3. **Parent places the child** in its coordinate space"

---

## How Layout Works: Parent and Child Negotiation

### Example 1: Simple Text Layout

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, SwiftUI!")
    }
}
```

**Layout conversation:**

```
Screen (Root):
  "I propose: (width: 393, height: 852)" [iPhone 14 screen size]
  
Text:
  "Looking at my content: 'Hello, SwiftUI!'"
  "With default font, I need: (width: 145, height: 21)"
  
Screen:
  "Okay, I'll center you at: (x: 124, y: 415.5)"
```

**Result:** Text appears centered on screen.

---

### Example 2: Nested Views

```swift
VStack {
    Text("Title")
    Text("Subtitle")
}
```

**Layout conversation:**

```
Screen:
  "VStack, you have: (width: 393, height: 852)"

VStack:
  "I need to layout my children..."
  
  To Text("Title"):
    "You have: (width: 393, height: unlimited)"
  
  Text("Title"):
    "I need: (width: 50, height: 21)"
  
  To Text("Subtitle"):
    "You have: (width: 393, height: 831)" [852 - 21 used by title]
  
  Text("Subtitle"):
    "I need: (width: 80, height: 21)"
  
  "Total size I need: (width: 80, height: 42)" [max width, sum heights]

Screen:
  "VStack, I'll place you at: (x: 156.5, y: 405)"
  
VStack:
  "Text('Title'), I'll place you at: (x: 0, y: 0)" [relative to VStack]
  "Text('Subtitle'), I'll place you at: (x: 0, y: 21)"
```

---

### The Proposed Size Types

When a parent proposes size, it can propose:

**1. Specific Size**
```swift
Text("Hello")
    .frame(width: 200, height: 100)
```
Parent proposes: `(width: 200, height: 100)`

**2. Flexible Size (nil)**
```swift
HStack {
    Text("Hello")  // HStack proposes: (width: nil, height: nil)
}
```
Meaning: "Take your ideal size"

**3. Infinity**
```swift
VStack {
    Text("Hello")  // VStack proposes: (width: screenWidth, height: .infinity)
}
```
Meaning: "You can have as much space as you want"

---

## Layout Priority and Flexibility

### View Categories by Flexibility

**1. Inflexible Views (Fixed Size)**

These views **ignore** parent's proposal and use their natural size:

```swift
Text("Hello")        // Size: Based on text content + font
Image("icon")        // Size: Image's natural dimensions
Circle()             // Size: Takes proposed size, but maintains aspect
```

**2. Flexible Views (Expanding)**

These views **use** parent's proposal (expand to fill):

```swift
Color.red           // Fills entire proposed space
Rectangle()         // Fills entire proposed space
Spacer()            // Expands to fill available space
```

**3. Layout Containers**

These negotiate with their children:

```swift
VStack              // Size: Based on children
HStack              // Size: Based on children
ZStack              // Size: Based on children
```

---

### The Priority System

When multiple views compete for space, **layout priority** determines who gets space first.

```swift
HStack {
    Text("Short")
        .layoutPriority(1)      // Higher priority
    
    Text("Very Long Text Here")
        .layoutPriority(0)      // Lower priority (default)
}
```

**Layout process:**
1. HStack allocates space to highest priority first (Text("Short"))
2. Remaining space goes to lower priority views
3. If not enough space, lower priority views get truncated

**Default priority:** 0
**Range:** -∞ to +∞

---

## Common Layout Modifiers

### .frame()

The most important layout modifier. Controls how a view responds to proposals.

**Syntax:**
```swift
.frame(width: CGFloat?, height: CGFloat?, alignment: Alignment = .center)
.frame(minWidth: CGFloat?, idealWidth: CGFloat?, maxWidth: CGFloat?,
       minHeight: CGFloat?, idealHeight: CGFloat?, maxHeight: CGFloat?,
       alignment: Alignment = .center)
```

**Behavior:**

```swift
// Fixed frame: View must be exactly this size
Text("Hello")
    .frame(width: 200, height: 100)
```

**Layout conversation:**
```
frame modifier:
  "Parent proposed: (300, 400)"
  "I override: propose (200, 100) to my child"
  
Text:
  "I got: (200, 100)"
  "My content needs: (50, 20)"
  "I'll report back: (200, 100)" [uses proposed size]
  
frame modifier:
  "Text is (200, 100), I'll report that to parent"
```

---

```swift
// Min/Max frame: View can be flexible within bounds
Text("Hello")
    .frame(minWidth: 100, maxWidth: 300)
```

**Layout conversation:**
```
frame modifier:
  "Parent proposed: (400, 100)"
  "My max is 300, so I propose: (300, 100) to child"
  
Text:
  "I need: (50, 20)"
  
frame modifier:
  "Text wants (50, 20)"
  "My min is 100, so I report: (100, 20)"
```

---

```swift
// .infinity: Expand to fill
Text("Hello")
    .frame(maxWidth: .infinity)
```

**Layout conversation:**
```
frame modifier:
  "Parent proposed: (300, 400)"
  "I propose to child: (300, 400)" [pass through width, maxWidth = .infinity]
  
Text:
  "I need: (50, 20)"
  
frame modifier:
  "Text wants (50, 20) width, but I have maxWidth: .infinity"
  "I'll report: (300, 20)" [expand width, keep text's height]
```

---

### .padding()

Adds space around a view.

```swift
Text("Hello")
    .padding()        // 16pt on all sides (default)
    .padding(20)      // 20pt on all sides
    .padding(.horizontal, 10)  // 10pt left and right
```

**Layout behavior:**

```swift
Text("Hello")
    .padding(20)
    .background(Color.blue)
```

**Layout conversation:**
```
padding modifier:
  "Parent proposed: (300, 400)"
  "I need 20pt padding on all sides"
  "I propose to child: (260, 360)" [subtract 40 from each dimension]
  
Text:
  "I need: (50, 20)"
  
padding modifier:
  "Text is (50, 20)"
  "Add padding: (50 + 40, 20 + 40)"
  "I report: (90, 60)"

background modifier:
  "I got: (90, 60)"
  "I'll make blue background that size"
```

**Result:** Blue rectangle 90×60 with text in center.

---

### .offset()

Moves view AFTER layout (doesn't affect layout).

```swift
Text("Hello")
    .offset(x: 50, y: 100)
```

**Critical:** `.offset()` happens AFTER layout, in the rendering phase.

**Layout conversation:**
```
offset modifier:
  "Parent proposed: (300, 400)"
  "I propose to child: (300, 400)" [pass through unchanged]
  
Text:
  "I need: (50, 20)"
  
offset modifier:
  "Text is (50, 20)"
  "I report: (50, 20)" [same size to parent]
  "But I'll render it shifted by (50, 100)"
```

**Important:** Parent thinks view is at original position. Can cause overlaps!

---

### .position()

Places view at absolute coordinates within parent.

```swift
Text("Hello")
    .position(x: 100, y: 200)
```

**Layout conversation:**
```
position modifier:
  "Parent proposed: (300, 400)"
  "I propose to child: (.infinity, .infinity)" [child can be any size]
  
Text:
  "I need: (50, 20)"
  
position modifier:
  "I'll report to parent: (300, 400)" [takes all proposed space]
  "I'll place Text centered at (100, 200)"
```

**Result:** Text appears at absolute position, but modifier claims entire parent space.

---

### .alignmentGuide()

Customizes how a view aligns within its parent.

```swift
Text("Hello")
    .alignmentGuide(.leading) { d in
        d[.leading] + 10  // Shift alignment 10pt right
    }
```

More advanced - typically used for custom alignments in stacks.

---

## Stack Layouts (HStack, VStack, ZStack)

### HStack Layout Algorithm

```swift
HStack {
    Text("A")
    Text("B")
    Text("C")
}
```

**HStack's process:**

**Step 1: Gather children**
```
Children: [Text("A"), Text("B"), Text("C")]
```

**Step 2: Determine flexibility**
```
- Propose to each child: (nil, proposedHeight)
- See which children are flexible vs inflexible
```

**Step 3: Allocate space**
```
1. Give inflexible children their ideal size
2. Divide remaining space among flexible children
3. Apply spacing between children (default: 8pt)
```

**Step 4: Place children**
```
Place each child left-to-right with spacing
```

---

### Example: HStack with Mixed Flexibility

```swift
HStack {
    Text("Short")           // Inflexible
    Color.red               // Flexible
    Text("Also Short")      // Inflexible
}
.frame(width: 300)
```

**Layout:**
```
HStack receives: (width: 300, height: unlimited)

Step 1: Propose (nil, unlimited) to all children
  Text("Short"): "I need (50, 20)"
  Color.red: "I'll take whatever" [flexible]
  Text("Also Short"): "I need (100, 20)"

Step 2: Allocate space
  Total width: 300
  Inflexible: 50 + 100 = 150
  Spacing: 8 + 8 = 16 (two gaps)
  Remaining: 300 - 150 - 16 = 134
  
Step 3: Give remaining to flexible views
  Color.red gets: 134 width

Step 4: Place
  Text("Short"): x = 0
  Color.red: x = 58 (50 + 8 spacing)
  Text("Also Short"): x = 200 (58 + 134 + 8)
```

**Result:** 
- Text("Short"): 50pt wide
- Color.red: 134pt wide
- Text("Also Short"): 100pt wide
- Total: 300pt

---

### VStack Layout Algorithm

Same as HStack but vertical:

```swift
VStack {
    Text("Top")
    Color.red
    Text("Bottom")
}
```

**Process:**
1. Propose (proposedWidth, nil) to measure natural heights
2. Allocate height to inflexible views first
3. Give remaining height to flexible views
4. Place top-to-bottom with spacing

---

### ZStack Layout Algorithm

```swift
ZStack {
    Rectangle()
    Text("Overlay")
}
```

**ZStack's process:**

**Step 1: Propose to all children**
```
All children get the SAME proposal from parent
```

**Step 2: Children choose sizes**
```
Rectangle: Takes full proposed size
Text: Takes natural size
```

**Step 3: ZStack's size**
```
ZStack reports the LARGEST size any child chose
(or proposed size if any child expanded)
```

**Step 4: Placement**
```
Each child centered (by default) within ZStack
```

---

### Stack Alignment

```swift
HStack(alignment: .top) {
    Text("Short")
    Text("Tall\nText")
}
```

**Alignment options:**

**HStack:**
- `.top` - Align tops
- `.center` (default) - Align centers
- `.bottom` - Align bottoms
- `.firstTextBaseline` - Align first line of text
- `.lastTextBaseline` - Align last line of text

**VStack:**
- `.leading` - Align left edges
- `.center` (default) - Align centers
- `.trailing` - Align right edges

**ZStack:**
- `.topLeading`, `.top`, `.topTrailing`
- `.leading`, `.center` (default), `.trailing`
- `.bottomLeading`, `.bottom`, `.bottomTrailing`

---

## Frame Modifiers Deep Dive

### The Order Matters

```swift
// Different results!

// Example 1:
Text("Hello")
    .background(Color.blue)  // 1. Background matches text size
    .frame(width: 200)       // 2. Then expand to 200

// Example 2:
Text("Hello")
    .frame(width: 200)       // 1. Expand to 200 first
    .background(Color.blue)  // 2. Background matches frame (200 wide)
```

**Example 1 result:** Blue background just around text, centered in 200pt space

**Example 2 result:** Blue background fills entire 200pt width

---

### Frame as a Container View

**Key insight:** `.frame()` creates a new container view!

```swift
Text("Hello")
    .frame(width: 200, height: 100)
```

**Is actually:**
```
FrameContainer(width: 200, height: 100) {
    Text("Hello")
}
```

The FrameContainer:
1. Receives proposal from parent
2. Proposes (200, 100) to child
3. Centers child within its bounds
4. Reports its size as (200, 100)

---

### Fixed vs Flexible Frames

**Fixed frame (both dimensions specified):**
```swift
Text("Hello")
    .frame(width: 200, height: 100)
```
Behavior: Exactly 200×100, always

---

**Flexible width, fixed height:**
```swift
Text("Hello")
    .frame(height: 100)
```
Behavior: Height fixed at 100, width adapts to content

---

**Bounded flexibility:**
```swift
Text("Hello")
    .frame(minWidth: 100, maxWidth: 300, height: 50)
```
Behavior: Width between 100-300 based on content, height fixed at 50

---

**Expand to fill:**
```swift
Text("Hello")
    .frame(maxWidth: .infinity, maxHeight: .infinity)
```
Behavior: Expands to fill all proposed space

---

### Frame Alignment

```swift
Text("Hello")
    .frame(width: 200, height: 100, alignment: .topLeading)
```

**Alignment options:**
- `.topLeading`, `.top`, `.topTrailing`
- `.leading`, `.center` (default), `.trailing`
- `.bottomLeading`, `.bottom`, `.bottomTrailing`

**What it does:** Controls where child sits within the frame's bounds if child is smaller than frame.

---

## Layout Debugging

### Visual Debugging with .border()

```swift
Text("Hello")
    .border(Color.red)           // Shows Text's exact bounds
    .frame(width: 200)
    .border(Color.blue)          // Shows frame's bounds
    .padding()
    .border(Color.green)         // Shows padding's bounds
```

Result: Three nested rectangles showing each container's size.

---

### Print Layout Information

```swift
extension View {
    func debugLayout() -> some View {
        background(
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        print("Size: \(geo.size)")
                        print("SafeArea: \(geo.safeAreaInsets)")
                    }
            }
        )
    }
}

// Usage:
Text("Hello")
    .debugLayout()
```

---

### Layout Inspector in Xcode

1. Run app in Simulator/Device
2. Debug menu → View Debugging → Capture View Hierarchy
3. 3D view of all views with sizes and positions
4. Click any view to see exact frame

---

### Using GeometryReader

```swift
GeometryReader { geometry in
    Text("Size: \(geometry.size.width) × \(geometry.size.height)")
}
```

**Important:** GeometryReader is greedy - takes all proposed space!

```swift
VStack {
    Text("Above")
    GeometryReader { geo in
        Text("Inside")
    }
    Text("Below")  // May be pushed off screen!
}
```

**Fix:** Give GeometryReader explicit height:
```swift
GeometryReader { geo in
    Text("Inside")
}
.frame(height: 100)
```

---

## Common Layout Patterns

### Pattern 1: Full-Width, Natural Height

```swift
Text("This text should be full width but only as tall as needed")
    .frame(maxWidth: .infinity)
```

**Use case:** Buttons, list items, headers

---

### Pattern 2: Centered with Max Size

```swift
VStack {
    Spacer()
    
    Text("Centered content")
        .frame(maxWidth: 300)
    
    Spacer()
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
```

**Use case:** Login forms, empty states

---

### Pattern 3: Equal-Width Siblings

```swift
HStack {
    Button("Cancel")
        .frame(maxWidth: .infinity)
    
    Button("Confirm")
        .frame(maxWidth: .infinity)
}
```

Both buttons get equal width (50% each).

---

### Pattern 4: Leading-Aligned with Flexible Content

```swift
HStack {
    Text("Label:")
        .frame(width: 100, alignment: .leading)
    
    TextField("Enter text", text: $text)
}
```

Label gets fixed 100pt, TextField gets remaining space.

---

### Pattern 5: Overlays

```swift
ZStack(alignment: .topTrailing) {
    Image("photo")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: 300, height: 200)
        .clipped()
    
    Text("New")
        .padding(8)
        .background(Color.red)
        .offset(x: -10, y: 10)
}
```

Badge positioned at top-right of image.

---

## Common Layout Problems

### Problem 1: GeometryReader Taking All Space

```swift
// ❌ PROBLEM:
VStack {
    Text("Title")
    
    GeometryReader { geo in
        Color.red
    }
    // GeometryReader expands to fill all remaining space!
    
    Text("Footer")  // Pushed to bottom or off-screen
}
```

**Solution 1: Give explicit height**
```swift
GeometryReader { geo in
    Color.red
}
.frame(height: 200)
```

**Solution 2: Use .background instead**
```swift
Color.red
    .frame(height: 200)
    .background(
        GeometryReader { geo in
            Color.clear
                .onAppear { print(geo.size) }
        }
    )
```

---

### Problem 2: Frame Order Wrong

```swift
// ❌ PROBLEM:
Text("Hello")
    .background(Color.blue)
    .frame(width: 200)
// Result: Background only around text, not full 200pt

// ✓ SOLUTION:
Text("Hello")
    .frame(width: 200)
    .background(Color.blue)
// Result: Background fills full 200pt
```

**Rule:** Apply `.frame()` before `.background()` if you want background to fill frame.

---

### Problem 3: Overlapping Views with .offset()

```swift
// ❌ PROBLEM:
VStack {
    Text("First")
        .offset(y: 100)  // Moves down but VStack doesn't know!
    
    Text("Second")  // Overlaps with First!
}
```

**Why:** `.offset()` doesn't affect layout, only rendering position.

**Solution 1: Use .padding() instead**
```swift
VStack {
    Text("First")
        .padding(.bottom, 100)  // Adds space in layout
    
    Text("Second")
}
```

**Solution 2: Use Spacer()**
```swift
VStack {
    Text("First")
    Spacer()
        .frame(height: 100)
    Text("Second")
}
```

---

### Problem 4: Text Truncation

```swift
// ❌ PROBLEM:
HStack {
    Text("Very Long Title That Gets Cut Off...")
    Spacer()
    Button("Action") { }
}
```

Button might push text truncation.

**Solution 1: Layout priority**
```swift
HStack {
    Text("Very Long Title That Gets Cut Off...")
        .layoutPriority(1)  // Give text priority
    
    Spacer()
    
    Button("Action") { }
        .layoutPriority(0)
}
```

**Solution 2: Fixed button width**
```swift
HStack {
    Text("Very Long Title That Gets Cut Off...")
    
    Spacer()
    
    Button("Action") { }
        .frame(width: 80)  // Button takes fixed space
}
```

---

### Problem 5: Unwanted Expansion

```swift
// ❌ PROBLEM:
VStack {
    Text("Title")
    Color.red  // Expands to fill all space!
}
```

**Solution: Give explicit size**
```swift
VStack {
    Text("Title")
    Color.red
        .frame(height: 100)  // Limit expansion
}
```

---

### Problem 6: Center Not Working

```swift
// ❌ PROBLEM:
Text("Center me")
    .frame(width: 200)
// Text is centered in the 200pt frame, but frame itself might not be centered in parent
```

**Solution: Explicitly center the frame**
```swift
HStack {
    Spacer()
    Text("Center me")
        .frame(width: 200)
    Spacer()
}
```

**Or use alignment:**
```swift
VStack {
    Text("Center me")
        .frame(width: 200)
}
.frame(maxWidth: .infinity)  // Parent fills width, centers child
```

---

### Problem 7: Safe Area Ignored

```swift
// ❌ PROBLEM:
Color.blue
    .edgesIgnoringSafeArea(.all)  // Deprecated!
```

**Solution (iOS 14+):**
```swift
Color.blue
    .ignoresSafeArea()
```

**Selective ignore:**
```swift
Color.blue
    .ignoresSafeArea(.container, edges: .top)  // Only top edge
```

---

## Advanced Concepts

### Custom Layout (iOS 16+)

Create fully custom layout logic:

```swift
struct CustomLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, 
                      subviews: Subviews, 
                      cache: inout ()) -> CGSize {
        // Return size based on subviews
    }
    
    func placeSubviews(in bounds: CGRect, 
                       proposal: ProposedViewSize, 
                       subviews: Subviews, 
                       cache: inout ()) {
        // Position each subview
    }
}
```

**Use case:** Completely custom layouts like masonry grids, flow layouts, etc.

---

### Layout in Habla App Context

**Your sticky header pattern:**
```swift
ScrollView {
    LazyVStack {
        // Content
    }
    .background(
        GeometryReader { geo in
            Color.clear
                .preference(key: ScrollOffsetKey.self, 
                           value: geo.frame(in: .named("scroll")).minY)
        }
    )
}
.coordinateSpace(name: "scroll")
```

**Layout flow:**
1. ScrollView proposes full height to LazyVStack
2. LazyVStack sizes based on visible content
3. GeometryReader in background takes same size
4. Reports scroll position via PreferenceKey
5. Parent reads preference and adjusts header

---

## Summary

### Key Takeaways

1. **Three-Step Process:**
   - Parent proposes → Child chooses → Parent places

2. **Flexibility:**
   - Some views are inflexible (Text, Image)
   - Some views expand (Color, Spacer)
   - Stacks negotiate with children

3. **Frame Order Matters:**
   ```swift
   .frame() → .background()  // Background fills frame
   .background() → .frame()  // Frame around background
   ```

4. **Offset vs Padding:**
   - `.offset()` - Moves visually, doesn't affect layout
   - `.padding()` - Adds space in layout

5. **GeometryReader is Greedy:**
   - Takes all proposed space
   - Give explicit frame when needed

### Mental Model

```
Screen
  └─ proposes (393, 852)
      └─ ContentView
          └─ VStack
              ├─ proposes (393, ∞) to Text
              │   └─ Text returns (100, 20)
              └─ proposes (393, ∞) to Button
                  └─ Button returns (80, 44)
              
VStack reports: (100, 64) [max width, sum heights]
Screen places VStack centered
VStack places children vertically
```

---

## Further Reading

- **WWDC 2019:** "Building Custom Views with SwiftUI"
- **WWCD 2022:** "Compose custom layouts with SwiftUI"
- **Apple Documentation:** [Layout Protocol](https://developer.apple.com/documentation/swiftui/layout)
- **objc.io:** "Thinking in SwiftUI" - Layout chapter

---

*Last Updated: December 2024*
