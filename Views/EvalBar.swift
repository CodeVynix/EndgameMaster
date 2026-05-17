import SwiftUI

struct EvalBar: View {
    var score: Double
    
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Color.black
                    .frame(height: geo.size.height * CGFloat(0.5 - score/2))
                
                Color.white
                    .frame(height: geo.size.height * CGFloat(0.5 + score/2))
            }
        }
        .frame(width: 25)
    }
}
