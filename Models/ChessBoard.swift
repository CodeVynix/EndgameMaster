import Foundation

struct ChessBoard {

    var board: [[Piece?]] = Array(
        repeating: Array(repeating: nil, count: 8),
        count: 8
    )

    var whiteToMove = true
    var enPassantTarget: (Int, Int)? = nil

    // MARK: - INIT (standard position)
    init() {
        setupInitial()
    }

    mutating func setupInitial() {
        let back: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]

        for i in 0..<8 {
            board[0][i] = Piece(type: back[i], color: .black)
            board[1][i] = Piece(type: .pawn, color: .black)

            board[6][i] = Piece(type: .pawn, color: .white)
            board[7][i] = Piece(type: back[i], color: .white)
        }
    }

    // MARK: - APPLY MOVE
    mutating func applyUCIMove(_ uci: String) {
        guard let move = UCIMove(uci: uci) else { return }

        var piece = board[move.from.rank][move.from.file]

        // EN PASSANT capture
        if let ep = enPassantTarget,
           piece?.type == .pawn,
           move.to == ep,
           board[move.to.rank][move.to.file] == nil {

            let dir = piece!.color == .white ? 1 : -1
            board[move.to.rank + dir][move.to.file] = nil
        }

        // MOVE
        board[move.to.rank][move.to.file] = piece
        board[move.from.rank][move.from.file] = nil

        // CASTLING
        if piece?.type == .king {
            if move.from.file == 4 && move.to.file == 6 {
                // king side
                board[move.to.rank][5] = board[move.to.rank][7]
                board[move.to.rank][7] = nil
            }
            if move.from.file == 4 && move.to.file == 2 {
                // queen side
                board[move.to.rank][3] = board[move.to.rank][0]
                board[move.to.rank][0] = nil
            }
        }

        // PROMOTION
        if let promo = move.promotion {
            if var p = board[move.to.rank][move.to.file] {
                switch promo {
                case "q": p.type = .queen
                case "r": p.type = .rook
                case "b": p.type = .bishop
                case "n": p.type = .knight
                default: break
                }
                board[move.to.rank][move.to.file] = p
            }
        }

        // SET EN PASSANT TARGET
        enPassantTarget = nil
        if piece?.type == .pawn {
            if abs(move.from.rank - move.to.rank) == 2 {
                let midRank = (move.from.rank + move.to.rank) / 2
                enPassantTarget = (midRank, move.from.file)
            }
        }

        whiteToMove.toggle()
    }

    // MARK: - FEN GENERATION
    func generateFEN() -> String {
        var fen = ""

        for rank in 0..<8 {
            var empty = 0
            for file in 0..<8 {
                if let piece = board[rank][file] {
                    if empty > 0 {
                        fen += "\(empty)"
                        empty = 0
                    }
                    fen += piece.fenSymbol
                } else {
                    empty += 1
                }
            }
            if empty > 0 { fen += "\(empty)" }
            if rank != 7 { fen += "/" }
        }

        fen += whiteToMove ? " w " : " b "

        // castling (simple always allow for now)
        fen += "KQkq "

        if let ep = enPassantTarget {
            let file = Character(UnicodeScalar(ep.1 + 97)!)
            let rank = 8 - ep.0
            fen += "\(file)\(rank) "
        } else {
            fen += "- "
        }

        fen += "0 1"

        return fen
    }
}
