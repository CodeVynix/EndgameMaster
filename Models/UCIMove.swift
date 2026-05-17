import Foundation

struct UCIMove {
    let from: (file: Int, rank: Int)
    let to: (file: Int, rank: Int)
    let promotion: Character?

    init?(uci: String) {
        guard uci.count >= 4 else { return nil }
        let c = Array(uci)

        func file(_ ch: Character) -> Int {
            Int(ch.asciiValue! - Character("a").asciiValue!)
        }

        func rank(_ ch: Character) -> Int {
            8 - Int(String(ch))!
        }

        from = (file(c[0]), rank(c[1]))
        to   = (file(c[2]), rank(c[3]))

        promotion = c.count == 5 ? c[4] : nil
    }
}
