import SwiftUI

struct SquareView: View {
    let position: Position
    let piece: Piece?
    let isHighlighted: Bool
    let isLastMove: Bool
    let isLegalMove: Bool
    let isHint: Bool
    
    var body: some View {
        ZStack {
            baseColor
            
            if isLastMove {
                Color.yellow.opacity(0.35)
            }
            
            if isHint {
                Color.green.opacity(0.5)
            }
            
            if isHighlighted {
                Color.blue.opacity(0.4)
            }
            
            if isLegalMove {
                Circle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: 12)
            }
            
            if let piece = piece {
                Text(piece.symbol)
                    .font(.system(size: 32))
            }
        }
    }
    
    private var baseColor: Color {
        (position.row + position.col) % 2 == 0
            ? Color(#colorLiteral(red: 0.95, green: 0.9, blue: 0.8, alpha: 1))
            : Color(#colorLiteral(red: 0.6, green: 0.4, blue: 0.25, alpha: 1))
    }
}
