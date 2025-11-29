//
//  LucentBorder.swift
//  PassportTravel
//
//  A lightweight SwiftUI modifier for adding elegant luminous borders
//  to any view with customizable corner radius, line width, and blur effects.
//
//  Created by Abdelkarim Achtaou on 29/11/2025.
//

import SwiftUI

// MARK: - View Modifier
struct LucentBorderModifier: ViewModifier {
    let radius: CGFloat
    let colors: [Color]
    let lineWidth: CGFloat
    let blurRadius: CGFloat
    let startingPoint: UnitPoint
    let endingPoint: UnitPoint

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: colors,
                            startPoint: startingPoint,
                            endPoint: endingPoint
                        ),
                        lineWidth: lineWidth
                    )
                    .blur(radius: blurRadius)
            }
    }
}

// MARK: - View Extension
extension View {
    /// Adds a luminous gradient border with customizable corner radius and glow effect
    ///
    /// Perfect for cards, buttons, containers, and any UI element that needs subtle depth and elegance.
    ///
    /// - Parameters:
    ///   - radius: Corner radius of the border (use `.infinity` for circles). Default is `16`.
    ///   - colors: Array of gradient colors for the border. Default creates adaptive light/dark mode effect.
    ///   - lineWidth: Thickness of the luminous border. Default is `0.6`.
    ///   - blurRadius: Amount of glow/blur effect. Default is `0.3`.
    ///   - startPoint: Starting point of the gradient. Default is `.topLeading`.
    ///   - endPoint: Ending point of the gradient. Default is `.bottomTrailing`.
    ///
    /// # Example Usage
    ///
    /// Basic usage:
    /// ```swift
    /// RoundedRectangle(cornerRadius: 16)
    ///     .fill(.ultraThinMaterial)
    ///     .frame(width: 200, height: 100)
    ///     .lucentBorder()
    /// ```
    ///
    /// Circular image with glow:
    /// ```swift
    /// Image("flag")
    ///     .resizable()
    ///     .frame(width: 50, height: 50)
    ///     .lucentBorder(radius: .infinity, lineWidth: 1, blurRadius: 0.2)
    /// ```
    ///
    /// Custom gradient colors:
    /// ```swift
    /// VStack { Text("Premium") }
    ///     .padding()
    ///     .background(.ultraThinMaterial)
    ///     .clipShape(RoundedRectangle(cornerRadius: 12))
    ///     .lucentBorder(
    ///         radius: 12,
    ///         colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
    ///         lineWidth: 0.5
    ///     )
    /// ```
    func lucentBorder(
        radius: CGFloat = 16,
        colors: [Color] = [
            Color(.sRGB, red: 0.25, green: 0.33, blue: 0.43, opacity: 0.6),  // Light mode stroke
            Color(.sRGB, red: 0.25, green: 0.33, blue: 0.43, opacity: 0.15),
            Color(.sRGB, red: 0.25, green: 0.33, blue: 0.43, opacity: 0.15),
            Color(.sRGB, red: 0.25, green: 0.33, blue: 0.43, opacity: 0.4)
        ],
        lineWidth: CGFloat = 0.6,
        blurRadius: CGFloat = 0.3,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> some View {
        modifier(LucentBorderModifier(
            radius: radius,
            colors: colors,
            lineWidth: lineWidth,
            blurRadius: blurRadius,
            startingPoint: startPoint,
            endingPoint: endPoint
        ))
    }

    /// Adds a customizable gradient stroke border
    ///
    /// Lower-level API for full control over the gradient stroke effect.
    ///
    /// - Parameters:
    ///   - radius: Corner radius of the border. Default is `25`.
    ///   - colors: Array of gradient colors. Default is gray gradient.
    ///   - lineWidth: Thickness of the border. Default is `1`.
    ///   - blurRadius: Amount of blur. Default is `1`.
    ///   - startPoint: Gradient start point. Default is `.topLeading`.
    ///   - endPoint: Gradient end point. Default is `.bottomTrailing`.
    func gradientStroke(
        radius: CGFloat = 25,
        colors: [Color] = [.gray.opacity(0.7), .gray.opacity(0.1)],
        lineWidth: CGFloat = 1,
        blurRadius: CGFloat = 1,
        startPoint: UnitPoint = .topLeading,
        endPoint: UnitPoint = .bottomTrailing
    ) -> some View {
        modifier(LucentBorderModifier(
            radius: radius,
            colors: colors,
            lineWidth: lineWidth,
            blurRadius: blurRadius,
            startingPoint: startPoint,
            endingPoint: endPoint
        ))
    }
}

// MARK: - Preview
#Preview("Basic Usage") {
    VStack(spacing: 24) {
        // Simple rounded rectangle
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .frame(width: 200, height: 100)
            .lucentBorder()

        // Circle
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 80, height: 80)
            .lucentBorder(radius: .infinity, lineWidth: 1, blurRadius: 0.2)

        // Card with content
        VStack(spacing: 8) {
            Text("Premium Card")
                .font(.headline)
            Text("With Lucent Border")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .lucentBorder(radius: 12, lineWidth: 0.5, blurRadius: 0.05)
    }
    .padding()
    .background(.gray.opacity(0.1))
}

#Preview("Custom Colors") {
    HStack(spacing: 16) {
        // Blue glow
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .frame(width: 100, height: 100)
            .lucentBorder(
                radius: 12,
                colors: [.blue.opacity(0.8), .blue.opacity(0.2)],
                lineWidth: 1,
                blurRadius: 0.4
            )

        // Purple glow
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .frame(width: 100, height: 100)
            .lucentBorder(
                radius: 12,
                colors: [.purple.opacity(0.8), .purple.opacity(0.2)],
                lineWidth: 1,
                blurRadius: 0.4
            )

        // Green glow
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .frame(width: 100, height: 100)
            .lucentBorder(
                radius: 12,
                colors: [.green.opacity(0.8), .green.opacity(0.2)],
                lineWidth: 1,
                blurRadius: 0.4
            )
    }
    .padding()
    .background(.gray.opacity(0.1))
}
