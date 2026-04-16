import Foundation

struct Position: Hashable, Codable {
    let row: Int
    let col: Int

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }

    var isValid: Bool {
        (0..<8).contains(row) && (0..<8).contains(col)
    }

    var algebraic: String {
        let file = Character(UnicodeScalar(col + 97) ?? "a")
        let rank = String(8 - row)
        return "\(file)\(rank)"
    }

    static func from(algebraic: String) -> Position? {
        guard algebraic.count == 2 else { return nil }
        let chars = Array(algebraic.lowercased())
        guard let file = chars.first?.asciiValue,
              ("a"..."h").contains(String(chars[0])),
              let rank = Int(String(chars[1])),
              (1...8).contains(rank) else {
            return nil
        }

        let col = Int(file - Character("a").asciiValue!)
        let row = 8 - rank
        let pos = Position(row: row, col: col)
        return pos.isValid ? pos : nil
    }
}
