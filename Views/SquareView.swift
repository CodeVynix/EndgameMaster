import SwiftUI

struct SquareView: View {
    let position: Position
    let piece: Piece?
    let isLight: Bool
    let isSelected: Bool
    let isLegalMove: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isLight ? Color(red: 0.94, green: 0.87, blue: 0.74) : Color(red: 0.56, green: 0.36, blue: 0.23))

            if isSelected {
                Rectangle()
                    .fill(Color.yellow.opacity(0.45))
            }

            if isLegalMove {
                Circle()
                    .fill(Color.green.opacity(0.85))
                    .frame(width: size * 0.25, height: size * 0.25)
            }

            if let piece {
                Image(piece.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
            }
        }
    }
}
