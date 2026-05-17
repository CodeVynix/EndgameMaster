import Foundation

struct Puzzle: Codable {
    let fen: String
    let solution: [String] // UCI moves
}

class PuzzleManager {
    
    static let shared = PuzzleManager()
    
    private(set) var puzzles: [Puzzle] = []
    private var index = 0
    
    init() {
        load()
    }
    
    private func load() {
        guard let url = Bundle.main.url(forResource: "puzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Puzzle].self, from: data) else {
            print("Failed to load puzzles")
            return
        }
        
        puzzles = decoded.shuffled()
    }
    
    func next() -> Puzzle? {
        guard !puzzles.isEmpty else { return nil }
        let p = puzzles[index % puzzles.count]
        index += 1
        return p
    }
}
