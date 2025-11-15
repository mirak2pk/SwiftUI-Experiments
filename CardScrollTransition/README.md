# Card Scroll Transition

![Demo](demo.gif)

A smooth card scrolling experience with scale, blur, and opacity transitions inspired by modern app designs.

## The Challenge

Create an engaging scroll experience where cards animate in as they enter the viewport, using SwiftUI's `scrollTransition` modifier to achieve smooth, performant animations.

## What I Learned

- **`scrollTransition` modifier** - SwiftUI's native way to animate views based on scroll position
- **Phase-based animations** - Using `phase.isIdentity` to determine visibility state
- **Combining transformations** - Layering scale, blur, offset, and opacity for rich effects
- **Lazy loading** - Using `LazyVStack` for performance with large lists
- **State management** - Handling selected items with smooth spring animations

## Key Features

- Cards scale up and fade in as they enter the viewport
- Smooth blur transition creates depth
- Tap to expand with spring animation
- Gradient overlays for text readability
- Shadow effects for card elevation

## How It Works

The magic happens in the `scrollTransition` closure:
```swift
.scrollTransition { content, phase in
    content
        .scaleEffect(phase.isIdentity ? 1 : 2)      // Scale from 2x to normal
        .blur(radius: phase.isIdentity ? 0 : 50)     // Blur when off-screen
        .offset(y: phase.isIdentity ? 0 : 100)       // Slide up effect
        .opacity(phase.isIdentity ? 1 : 0)           // Fade in
}
```

When `phase.isIdentity` is true, the view is fully visible. Otherwise, it's transitioning in/out.

## Usage

1. Replace the placeholder images (`img1`, `img2`, etc.) with your own assets
2. Copy the file into your project
3. Add `ContentViewA()` to your app

## Screen Recording

[Watch the demo](link-to-reddit-post)

## Notes

This was a fun exploration of SwiftUI's scroll transition APIs. The combination of scale + blur + offset creates a really satisfying entrance effect. The tap-to-expand feature is a bonus that could be extended into a full detail view.

Built with Claude AI after experimenting with different transition combinations to find what felt most natural.

---

**Difficulty:** Beginner-Intermediate  
**SwiftUI Concepts:** ScrollTransition, LazyVStack, State Management, View Modifiers
