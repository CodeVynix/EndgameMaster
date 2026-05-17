import Foundation

enum PieceType {
    case king, queen, rook, bishop, knight, pawn
}

enum PieceColor {
    case white, black
}

struct Piece {
    var type: PieceType
    var color: PieceColor

    var fenSymbol: String {
        let symbol: String
        switch type {
        case .king: symbol = "k"
        case .queen: symbol = "q"
        case .rook: symbol = "r"
        case .bishop: symbol = "b"
        case .knight: symbol = "n"
        case .pawn: symbol = "p"
        }

        return color == .white ? symbol.uppercased() : symbol
    }
}
