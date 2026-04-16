import Foundation

enum PuzzleDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

struct Puzzle: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let fen: String
    let solution: [String]
    let difficulty: PuzzleDifficulty

    init(id: UUID = UUID(), title: String, fen: String, solution: [String], difficulty: PuzzleDifficulty) {
        self.id = id
        self.title = title
        self.fen = fen
        self.solution = solution
        self.difficulty = difficulty
    }
}
