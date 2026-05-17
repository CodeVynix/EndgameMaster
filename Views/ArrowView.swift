import SwiftUI

struct ArrowView: View {

    let from: (Int, Int)
    let to: (Int, Int)

    var body: some View {
        GeometryReader { geo in
            let squareSize = geo.size.width / 8

            let start = CGPoint(
                x: CGFloat(from.1) * squareSize + squareSize/2,
                y: CGFloat(from.0) * squareSize + squareSize/2
            )

            let end = CGPoint(
                x: CGFloat(to.1) * squareSize + squareSize/2,
                y: CGFloat(to.0) * squareSize + squareSize/2
            )

            Path { path in
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(Color.blue, lineWidth: 4)
        }
    }
}
