import Foundation

enum PieceColor: String, Codable {
    case white
    case black

    var opposite: PieceColor {
        self == .white ? .black : .white
    }
}

enum PieceType: String, Codable {
    case king
    case queen
    case rook
    case bishop
    case knight
    case pawn

    var fenSymbol: String {
        switch self {
        case .king: return "k"
        case .queen: return "q"
        case .rook: return "r"
        case .bishop: return "b"
        case .knight: return "n"
        case .pawn: return "p"
        }
    }
}

struct Piece: Codable, Hashable {
    let type: PieceType
    let color: PieceColor

    var imageName: String {
        "\(color.rawValue)_\(type.rawValue)"
    }

    var fenCharacter: String {
        let symbol = type.fenSymbol
        return color == .white ? symbol.uppercased() : symbol
    }
}
