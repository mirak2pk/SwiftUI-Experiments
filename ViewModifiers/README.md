# LucentBorder

A handmade lightweight SwiftUI view modifier that adds elegant, luminous borders to any view with customizable corner radius, line width, and blur effects.

<p align="center">
  <img src="https://img.shields.io/badge/Platform-iOS%2015.0%2B-blue.svg" alt="Platform: iOS 15.0+">
  <img src="https://img.shields.io/badge/Swift-5.5%2B-orange.svg" alt="Swift 5.5+">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT">
</p>

## Overview

**LucentBorder** (currently named `shinyEdges` in code) creates smooth, glowing edge effects that enhance your SwiftUI views with a premium, glass-like appearance. Perfect for cards, buttons, containers, and any UI element that needs subtle depth and elegance.

## Features

- ✨ **Smooth luminous borders** with customizable glow
- 🎨 **Adaptive to any corner radius** (circles, rounded rectangles, custom shapes)
- ⚡️ **Lightweight** - Pure SwiftUI, no external dependencies
- 🎯 **Highly customizable** - Control line width, blur, and radius
- 🌈 **Works with any color scheme** (light/dark mode compatible)

## Preview

```swift
// Simple usage
RoundedRectangle(cornerRadius: 16)
    .fill(.ultraThinMaterial)
    .frame(width: 200, height: 100)
    .shinyEdges()

// Advanced customization
Image("flag")
    .resizable()
    .frame(width: 80, height: 80)
    .shinyEdges(radius: .infinity, lineWidth: 1, blurRadius: 0.2)

// On cards
VStack {
    Text("Premium Card")
}
.padding()
.background(Color.cardBackground)
.clipShape(RoundedRectangle(cornerRadius: 12))
.shinyEdges(lineWidth: 0.5, blurRadius: 0.05)
```

## Installation

### Manual Installation

1. Copy the `shinyEdges` view modifier extension to your project
2. Use it on any SwiftUI view

```swift
extension View {
    func shinyEdges(
        radius: CGFloat = 12,
        lineWidth: CGFloat = 0.5,
        blurRadius: CGFloat = 0.4
    ) -> some View {
        // Implementation here
    }
}
```

## Usage

### Basic Usage

Apply the modifier to any view:

```swift
VStack {
    Text("Hello, World!")
}
.padding()
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 16))
.shinyEdges()
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `radius` | `CGFloat` | `12` | Corner radius of the border (use `.infinity` for circles) |
| `lineWidth` | `CGFloat` | `0.5` | Thickness of the luminous border |
| `blurRadius` | `CGFloat` | `0.4` | Amount of glow/blur effect |

### Advanced Examples

#### Circular Flag with Glow
```swift
Image("country-flag")
    .resizable()
    .scaledToFit()
    .frame(width: 50, height: 50)
    .shinyEdges(radius: .infinity, lineWidth: 1, blurRadius: 0.2)
```

#### Subtle Card Border
```swift
VStack(spacing: 12) {
    Text("Achievement Unlocked")
        .font(.headline)
    Text("First Country Visited")
        .font(.caption)
}
.padding()
.background(Color.cardBackground)
.clipShape(RoundedRectangle(cornerRadius: 16))
.shinyEdges(lineWidth: 0.5, blurRadius: 0.05)
```

#### Dynamic Map Mask
```swift
Map()
    .mask(alignment: .top) {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .frame(height: height)
            .shinyEdges(radius: cornerRadius)
    }
```

## Best Practices

### Performance Tips

- **Avoid blur on frequently updating views** - Blur effects can be GPU-intensive
- **Use lower `blurRadius` values** (0.05-0.2) for better performance
- **Don't combine with GeometryReader on scroll** - Can cause Metal rendering issues

### Design Guidelines

- **Subtle is better** - Use `lineWidth: 0.5` and `blurRadius: 0.05` for professional look
- **Match corner radius** - Always pass the same radius used in `clipShape`
- **Dark mode compatibility** - The effect adapts automatically to color schemes

## Common Use Cases

1. **Photo/Flag borders** - Use `radius: .infinity` for circular images
2. **Card containers** - Subtle glow on background cards
3. **Achievement badges** - Enhanced depth on reward UI
4. **Map overlays** - Smooth edges on masked map views
5. **Premium buttons** - Add elegance to CTAs

### Issue: Border doesn't match shape

**Problem:** Radius mismatch between `clipShape` and `shinyEdges`

**Solution:** Always use the same radius value

```swift
// ✅ Correct
.clipShape(RoundedRectangle(cornerRadius: 16))
.shinyEdges(radius: 16)

// ❌ Mismatched
.clipShape(RoundedRectangle(cornerRadius: 16))
.shinyEdges(radius: 12) // Wrong!
```

## Requirements

- iOS 15.0+
- macOS 12.0+
- tvOS 15.0+
- watchOS 8.0+
- Swift 5.5+

## Author

Created with ❤️ for the SwiftUI community

## License

MIT License - Feel free to use in personal and commercial projects

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
