import SwiftUI

struct ThinkingDots: View {
    
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 8) {
            dot(delay: 0)
            dot(delay: 0.2)
            dot(delay: 0.4)
        }
        .padding(16)
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .onAppear {
            animate = true
        }
    }
    
    private func dot(delay: Double) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .scaleEffect(animate ? 1 : 0.5)
            .opacity(animate ? 1 : 0.3)
            .animation(
                Animation.easeInOut(duration: 0.6)
                    .repeatForever()
                    .delay(delay),
                value: animate
            )
    }
}
