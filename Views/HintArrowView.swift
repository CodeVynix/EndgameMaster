import SwiftUI

struct HintArrowView: View {
    
    var from: Int
    var to: Int
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width / 8
            
            let fromX = CGFloat(from % 8) * size + size/2
            let fromY = CGFloat(7 - from / 8) * size + size/2
            
            let toX = CGFloat(to % 8) * size + size/2
            let toY = CGFloat(7 - to / 8) * size + size/2
            
            Path { path in
                path.move(to: CGPoint(x: fromX, y: fromY))
                path.addLine(to: CGPoint(x: toX, y: toY))
            }
            .stroke(Color.green.opacity(0.8), lineWidth: 4)
        }
    }
}
