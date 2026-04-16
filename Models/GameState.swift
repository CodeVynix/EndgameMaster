import Foundation

enum GameMode: String, Codable {
    case puzzle
    case aiMatch
}

struct GameState {
    var mode: GameMode = .puzzle
    var currentTurn: PieceColor = .white
    var statusMessage: String = "Ready"
    var isSolved: Bool = false
    var isCheckmate: Bool = false
}
