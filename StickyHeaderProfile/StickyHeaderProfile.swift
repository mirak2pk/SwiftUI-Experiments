import SwiftUI

struct StickyHeaderProfile: View {
    @State private var redOffsetAmount: CGFloat = 0
    @State private var maxY: CGFloat = 0
    @State var geoValues = [(String, CGFloat)]()
    @State private var isClicked = false
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .top) {
                // Content that scrolls normally
                LazyVStack {
                    ForEach(0..<50) { i in
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(.mint.opacity(0.1))
                            .frame(height: 80)
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                    }
                }
                .padding(.horizontal)
                .safeAreaPadding(.top, 100) // Space for sticky header
                
                // Sticky header that stays at top
                stickyHeaderView()
                    .padding(.horizontal)
            }
        }
        .coordinateSpace(.named("scroll")) // Named coordinate space to track scroll position
    }
    
    /// Creates a sticky header that scales and morphs as you scroll
    /// Uses GeometryReader to track position and calculate dynamic properties
    func stickyHeaderView() -> some View {
        GeometryReader { geo in
            // Track vertical position in scroll coordinate space
            let minY = geo.frame(in: .named("scroll")).minY
            let minX = geo.frame(in: .named("scroll")).minX
            
            // Calculate offset (how much we've scrolled)
            let offset = max(-minY, 0)
            
            // Progress from 0 to 1 based on scroll distance
            // Dividing by 100 means full transition happens over 100 points
            let progress = max(min(offset / 100, 1), 0)
            
            // Dynamic properties based on scroll progress
            let scale = 1 + progress * 1              // Scale from 1x to 2x
            let textSize1 = 23 - (progress * 2)       // Main text shrinks 23 → 21
            let textSize2 = 16 - (progress * 1)       // Subtitle shrinks 16 → 15
            let imageRadius = 12 + (progress * 20)    // Corner radius 12 → 32 (circular)
            
            // Horizontal offset compensation to keep content aligned when sticky
            let offsetX = max(-offset, -minX)
            
            ZStack {
                // Background with glassmorphism effect
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .lightShadow()
                    .scaleEffect(scale, anchor: .bottom) // Scale from bottom
                    .offset(y: offset) // Stick to top
                
                // Profile content
                HStack(spacing: 16) {
                    // Profile image with dynamic corner radius
                    Image("profile")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: imageRadius))
                    
                    // Text content with dynamic sizing
                    VStack(alignment: .leading, spacing: -1) {
                        Text("Jason Chweng")
                            .font(.system(size: textSize1, weight: .bold, design: .rounded))
                            .tracking(-1)
                        
                        Text("iOS Engineer")
                            .font(.system(size: textSize2, weight: .regular))
                    }
                    
                    Spacer()
                }
                .padding(8)
                .offset(y: offset) // Stick to top
                .offset(x: offsetX) // Compensate horizontal drift
                
                // DEBUG OVERLAY - Uncomment to see values in real-time
                // Helpful for understanding the math while learning
                .overlay {
                    VStack {
                        Text("[minY \(minY.int)] [offset \(offset.int)] [progress \(progress)]")
                        Text("scale \(scale)")
                        Text("X offset \(-offset)")
                        Text("text1 \(textSize1) text2 \(textSize2)")
                    }
                    .padding(.top, 200)
                    .opacity(0) // Set to 0.8 to see debug info
                }
            }
        }
        .frame(height: 80) // Fixed height for the header
    }
}

// MARK: - Extensions

extension View {
    /// Adds a subtle shadow for depth
    func lightShadow() -> some View {
        self.shadow(color: .black.opacity(0.1), radius: 8, y: 10)
    }
}

extension CGFloat {
    /// Quick conversion to Int for debug display
    var int: Int {
        Int(self)
    }
}

#Preview {
    StickyHeaderProfile()
}

// MARK: - Usage Notes
/*
 To use this in your project:
 
 1. Add a profile image to Assets.xcassets named "profile"
    OR change "profile" to your image name
 
 2. Copy this entire file to your project
 
 3. Use StickyHeaderProfile() in your app
 
 Tips for customization:
 - Change transition speed: adjust the `/ 100` value in progress calculation
   (smaller = faster transition, larger = slower)
 
 - Adjust scale range: modify `progress * 1` (e.g., `progress * 0.5` for less scale)
 
 - Change text sizes: adjust the base sizes (23, 16) and multipliers
 
 - Replace mint rectangles with your actual content (posts, messages, etc.)
 
 - Enable debug overlay: set opacity to 0.8 to see calculations in action
 
 How the math works:
 - minY starts at 0 when header is at top, goes negative as you scroll down
 - offset converts negative minY to positive scroll distance
 - progress normalizes offset to 0-1 range for smooth interpolation
 - All dynamic properties use progress to transition smoothly
 
 Built with SwiftUI + Claude AI
 */
