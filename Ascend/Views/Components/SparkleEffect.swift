import SwiftUI

struct SparkleEffect: View {
    let count: Int
    let iconSize: CGFloat
    
    init(count: Int = 4, iconSize: CGFloat = 60) {
        self.count = count
        self.iconSize = iconSize
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { index in
                SparkleParticleView(
                    index: index,
                    count: count,
                    iconSize: iconSize
                )
            }
        }
    }
}

struct SparkleParticleView: View {
    let index: Int
    let count: Int
    let iconSize: CGFloat
    @State private var opacity: Double = 0.0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.3
    
    private var angle: Double {
        Double(index) * (2 * .pi / Double(count))
    }
    
    private var offset: CGSize {
        let radius = iconSize * 0.6
        return CGSize(
            width: CGFloat(cos(angle)) * radius,
            height: CGFloat(sin(angle)) * radius
        )
    }
    
    private var icon: String {
        let icons = ["sparkles", "star.fill", "star.circle.fill"]
        return icons[index % icons.count]
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 10 + scale * 4))
            .foregroundColor(.yellow.opacity(opacity))
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .onAppear {
                let delay = Double(index) * 0.1
                let duration = 1.5 + Double.random(in: 0...0.5)
                
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .delay(delay)
                        .repeatForever(autoreverses: true)
                ) {
                    opacity = 0.8
                    scale = 1.0
                }
                
                withAnimation(
                    Animation.linear(duration: duration * 2)
                        .delay(delay)
                        .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

struct SparkleEffectModifier: ViewModifier {
    let count: Int
    let iconSize: CGFloat
    @State private var showSparkles = false
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if showSparkles {
                SparkleEffect(count: count, iconSize: iconSize)
            }
        }
        .onAppear {
            withAnimation {
                showSparkles = true
            }
        }
    }
}

extension View {
    func sparkleEffect(count: Int = 4, iconSize: CGFloat = 60) -> some View {
        self.modifier(SparkleEffectModifier(count: count, iconSize: iconSize))
    }
}

