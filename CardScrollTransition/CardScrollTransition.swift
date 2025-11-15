import SwiftUI

// MARK: - Model
struct CardItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let image: String
}

// MARK: - Sample Data
extension CardItem {
    /// Replace these image names with your own assets in Assets.xcassets
    /// You can use SF Symbols, system images, or your own photos
    static let samples: [CardItem] = [
        CardItem(title: "Mountains", subtitle: "Explore the peaks", image: "img1"),
        CardItem(title: "Ocean", subtitle: "Dive into the blue", image: "img2"),
        CardItem(title: "Forest", subtitle: "Walk among trees", image: "img3"),
        CardItem(title: "Desert", subtitle: "Feel the heat", image: "img4"),
        CardItem(title: "City", subtitle: "Urban adventures", image: "img5"),
        CardItem(title: "Lakes", subtitle: "Peaceful waters", image: "img6"),
        CardItem(title: "Valleys", subtitle: "Hidden gems", image: "img7"),
        CardItem(title: "Rivers", subtitle: "Flow with nature", image: "img8"),
        CardItem(title: "Clouds", subtitle: "Touch the sky", image: "img9"),
        CardItem(title: "Sunrise", subtitle: "New beginnings", image: "img10"),
    ]
}

// MARK: - Card View
struct CardItemView: View {
    let item: CardItem
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image
            Image(item.image)
                .resizable()
                .scaledToFill()
                .frame(minHeight: 200)
                .clipped()
            
            // Gradient Overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(Rectangle()) // Makes entire card tappable
    }
}

// MARK: - Main View
struct ContentViewA: View {
    var items = CardItem.samples
    @State private var selectedItem: CardItem? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(items, id: \.id) { item in
                            cardItem(for: item)
                                .frame(height: selectedItem == item ? 250 : 200)
                                .onTapGesture {
                                    withAnimation(.spring) {
                                        // Tap to expand/collapse card
                                        // You can extend this to navigate to a detail view
                                        selectedItem = selectedItem == item ? nil : item
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                }
            }
        }
    }
    
    /// Creates a card with scroll-based transitions
    /// Cards will scale, blur, and fade as they enter/exit the viewport
    @ViewBuilder
    func cardItem(for item: CardItem) -> some View {
        CardItemView(item: item)
            .scrollTransition { content, phase in
                content
                    // Scale effect: cards start at 2x and scale down to normal
                    .scaleEffect(phase.isIdentity ? 1 : 2)
                    // Blur effect: creates depth as cards enter view
                    .blur(radius: phase.isIdentity ? 0 : 50)
                    // Offset: cards slide up into position
                    .offset(y: phase.isIdentity ? 0 : 100)
                    // Opacity: fade in smoothly
                    .opacity(phase.isIdentity ? 1 : 0)
            }
    }
}

#Preview {
    ContentViewA()
}

// MARK: - Usage Notes
/*
 To use this in your project:
 
 1. Add 10 images to your Assets.xcassets named img1, img2, ... img10
    OR use SF Symbols like "mountain.2.fill", "water.waves", etc.
    OR use your own image names and update the CardItem.samples array
 
 2. Copy this entire file to your project
 
 3. Use ContentViewA() in your app or preview
 
 Tips for customization:
 - Adjust transition values in scrollTransition for different effects
 - Change card heights, corner radius, or spacing
 - Extend selectedItem behavior to show a detail view
 - Swap LazyVStack with LazyVGrid for a grid layout
 
 Built with SwiftUI + Claude AI
 */
