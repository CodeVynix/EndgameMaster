import SwiftUI

struct Arrow: Identifiable {
    let id = UUID()
    let from: CGPoint
    let to: CGPoint
}

class ArrowManager: ObservableObject {
    @Published var arrows: [Arrow] = []
}

struct ArrowOverlay: View {
    @ObservedObject var manager: ArrowManager
    
    var body: some View {
        GeometryReader { geo in
            ForEach(manager.arrows) { arrow in
                Path { path in
                    path.move(to: arrow.from)
                    path.addLine(to: arrow.to)
                }
                .stroke(Color.red, lineWidth: 3)
            }
        }
    }
}
