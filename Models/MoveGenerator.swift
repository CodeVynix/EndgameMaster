import Foundation

struct MoveGenerator {

    static func legalMoves(from square: (Int, Int), board: ChessBoard) -> [(Int, Int)] {
        guard let piece = board.board[square.0][square.1] else { return [] }

        var moves: [(Int, Int)] = []

        func inside(_ r: Int, _ f: Int) -> Bool {
            return r >= 0 && r < 8 && f >= 0 && f < 8
        }

        let (r, f) = square

        switch piece.type {

        case .pawn:
            let dir = piece.color == .white ? -1 : 1
            let startRank = piece.color == .white ? 6 : 1

            // forward
            if inside(r+dir, f) && board.board[r+dir][f] == nil {
                moves.append((r+dir, f))

                if r == startRank && board.board[r+2*dir][f] == nil {
                    moves.append((r+2*dir, f))
                }
            }

            // captures
            for df in [-1, 1] {
                let nr = r+dir
                let nf = f+df
                if inside(nr, nf) {
                    if let target = board.board[nr][nf],
                       target.color != piece.color {
                        moves.append((nr, nf))
                    }
                }
            }

        case .knight:
            let offsets = [(2,1),(2,-1),(-2,1),(-2,-1),(1,2),(1,-2),(-1,2),(-1,-2)]
            for (dr, df) in offsets {
                let nr = r+dr, nf = f+df
                if inside(nr, nf),
                   board.board[nr][nf]?.color != piece.color {
                    moves.append((nr,nf))
                }
            }

        case .bishop, .rook, .queen:
            let directions: [(Int,Int)] = {
                switch piece.type {
                case .bishop: return [(1,1),(1,-1),(-1,1),(-1,-1)]
                case .rook: return [(1,0),(-1,0),(0,1),(0,-1)]
                default: return [(1,1),(1,-1),(-1,1),(-1,-1),(1,0),(-1,0),(0,1),(0,-1)]
                }
            }()

            for (dr, df) in directions {
                var nr = r+dr, nf = f+df
                while inside(nr, nf) {
                    if let target = board.board[nr][nf] {
                        if target.color != piece.color {
                            moves.append((nr,nf))
                        }
                        break
                    }
                    moves.append((nr,nf))
                    nr += dr
                    nf += df
                }
            }

        case .king:
            for dr in -1...1 {
                for df in -1...1 {
                    if dr == 0 && df == 0 { continue }
                    let nr = r+dr, nf = f+df
                    if inside(nr,nf),
                       board.board[nr][nf]?.color != piece.color {
                        moves.append((nr,nf))
                    }
                }
            }
        }

        return moves
    }
}
