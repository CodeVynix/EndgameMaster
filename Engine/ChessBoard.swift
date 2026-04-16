import Foundation

struct MoveResult {
    let didCapture: Bool
}

struct ChessBoard {
    private(set) var grid: [[Piece?]] = Array(
        repeating: Array(repeating: nil, count: 8),
        count: 8
    )

    init() {
        loadStandardPosition()
    }

    mutating func clear() {
        grid = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    }

    func piece(at position: Position) -> Piece? {
        guard position.isValid else { return nil }
        return grid[position.row][position.col]
    }

    mutating func setPiece(_ piece: Piece?, at position: Position) {
        guard position.isValid else { return }
        grid[position.row][position.col] = piece
    }

    mutating func loadStandardPosition() {
        clear()
        for col in 0..<8 {
            setPiece(Piece(type: .pawn, color: .white), at: Position(row: 6, col: col))
            setPiece(Piece(type: .pawn, color: .black), at: Position(row: 1, col: col))
        }

        let backRank: [PieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for col in 0..<8 {
            setPiece(Piece(type: backRank[col], color: .white), at: Position(row: 7, col: col))
            setPiece(Piece(type: backRank[col], color: .black), at: Position(row: 0, col: col))
        }
    }

    mutating func loadFEN(_ fen: String) {
        clear()
        let segments = fen.split(separator: " ")
        guard let boardSegment = segments.first else { return }
        let ranks = boardSegment.split(separator: "/")
        guard ranks.count == 8 else { return }

        for (row, rank) in ranks.enumerated() {
            var col = 0
            for character in rank {
                if let emptyCount = Int(String(character)) {
                    col += emptyCount
                    continue
                }

                guard col < 8 else { continue }
                let color: PieceColor = character.isUppercase ? .white : .black
                let normalized = String(character).lowercased()
                let type: PieceType?
                switch normalized {
                case "k": type = .king
                case "q": type = .queen
                case "r": type = .rook
                case "b": type = .bishop
                case "n": type = .knight
                case "p": type = .pawn
                default: type = nil
                }
                if let type {
                    setPiece(Piece(type: type, color: color), at: Position(row: row, col: col))
                }
                col += 1
            }
        }
    }

    func generateFEN(activeColor: PieceColor) -> String {
        var rows: [String] = []
        for row in 0..<8 {
            var rowString = ""
            var emptyCount = 0
            for col in 0..<8 {
                let position = Position(row: row, col: col)
                if let piece = piece(at: position) {
                    if emptyCount > 0 {
                        rowString += "\(emptyCount)"
                        emptyCount = 0
                    }
                    rowString += piece.fenCharacter
                } else {
                    emptyCount += 1
                }
            }
            if emptyCount > 0 {
                rowString += "\(emptyCount)"
            }
            rows.append(rowString)
        }

        let turn = activeColor == .white ? "w" : "b"
        return rows.joined(separator: "/") + " \(turn) - - 0 1"
    }

    static func parseMove(_ move: String) -> (from: Position, to: Position)? {
        guard move.count >= 4 else { return nil }
        let fromString = String(move.prefix(2))
        let toString = String(move.dropFirst(2).prefix(2))
        guard let from = Position.from(algebraic: fromString),
              let to = Position.from(algebraic: toString) else {
            return nil
        }
        return (from, to)
    }

    func findKing(color: PieceColor) -> Position? {
        for row in 0..<8 {
            for col in 0..<8 {
                let pos = Position(row: row, col: col)
                if let piece = piece(at: pos), piece.type == .king, piece.color == color {
                    return pos
                }
            }
        }
        return nil
    }

    func isKingInCheck(color: PieceColor) -> Bool {
        guard let kingPosition = findKing(color: color) else { return false }
        return isSquareAttacked(kingPosition, by: color.opposite)
    }

    func isCheckmate(color: PieceColor) -> Bool {
        guard isKingInCheck(color: color) else { return false }
        for row in 0..<8 {
            for col in 0..<8 {
                let from = Position(row: row, col: col)
                guard let piece = piece(at: from), piece.color == color else { continue }
                if !legalMoves(from: from, color: color).isEmpty {
                    return false
                }
            }
        }
        return true
    }

    func legalMoves(from: Position, color: PieceColor) -> [Position] {
        guard let piece = piece(at: from), piece.color == color else { return [] }
        let pseudoMoves = pseudoLegalMoves(from: from, piece: piece)
        return pseudoMoves.filter { target in
            var clone = self
            _ = clone.applyMoveUnchecked(from: from, to: target)
            return !clone.isKingInCheck(color: color)
        }
    }

    func isLegalMove(from: Position, to: Position, color: PieceColor) -> Bool {
        legalMoves(from: from, color: color).contains(to)
    }

    mutating func move(from: Position, to: Position, color: PieceColor) -> MoveResult? {
        guard isLegalMove(from: from, to: to, color: color) else { return nil }
        return applyMoveUnchecked(from: from, to: to)
    }

    @discardableResult
    private mutating func applyMoveUnchecked(from: Position, to: Position) -> MoveResult? {
        guard let movingPiece = piece(at: from) else { return nil }
        let didCapture = piece(at: to) != nil
        setPiece(nil, at: from)
        setPiece(movingPiece, at: to)
        return MoveResult(didCapture: didCapture)
    }

    private func pseudoLegalMoves(from: Position, piece: Piece) -> [Position] {
        switch piece.type {
        case .king:
            return kingMoves(from: from, color: piece.color)
        case .queen:
            return slidingMoves(from: from, color: piece.color, directions: [
                (-1, 0), (1, 0), (0, -1), (0, 1), (-1, -1), (-1, 1), (1, -1), (1, 1)
            ])
        case .rook:
            return slidingMoves(from: from, color: piece.color, directions: [(-1, 0), (1, 0), (0, -1), (0, 1)])
        case .bishop:
            return slidingMoves(from: from, color: piece.color, directions: [(-1, -1), (-1, 1), (1, -1), (1, 1)])
        case .knight:
            return knightMoves(from: from, color: piece.color)
        case .pawn:
            return pawnMoves(from: from, color: piece.color)
        }
    }

    private func kingMoves(from: Position, color: PieceColor) -> [Position] {
        let offsets = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]
        return offsets.compactMap { dx, dy in
            let target = Position(row: from.row + dx, col: from.col + dy)
            guard target.isValid else { return nil }
            if let targetPiece = piece(at: target), targetPiece.color == color {
                return nil
            }
            return target
        }
    }

    private func knightMoves(from: Position, color: PieceColor) -> [Position] {
        let offsets = [
            (-2, -1), (-2, 1),
            (-1, -2), (-1, 2),
            (1, -2),  (1, 2),
            (2, -1),  (2, 1)
        ]
        return offsets.compactMap { dx, dy in
            let target = Position(row: from.row + dx, col: from.col + dy)
            guard target.isValid else { return nil }
            if let targetPiece = piece(at: target), targetPiece.color == color {
                return nil
            }
            return target
        }
    }

    private func slidingMoves(from: Position, color: PieceColor, directions: [(Int, Int)]) -> [Position] {
        var moves: [Position] = []
        for (dx, dy) in directions {
            var current = Position(row: from.row + dx, col: from.col + dy)
            while current.isValid {
                if let targetPiece = piece(at: current) {
                    if targetPiece.color != color {
                        moves.append(current)
                    }
                    break
                } else {
                    moves.append(current)
                }
                current = Position(row: current.row + dx, col: current.col + dy)
            }
        }
        return moves
    }

    private func pawnMoves(from: Position, color: PieceColor) -> [Position] {
        var moves: [Position] = []
        let direction = color == .white ? -1 : 1
        let startRow = color == .white ? 6 : 1

        let oneStep = Position(row: from.row + direction, col: from.col)
        if oneStep.isValid, piece(at: oneStep) == nil {
            moves.append(oneStep)
            let twoStep = Position(row: from.row + 2 * direction, col: from.col)
            if from.row == startRow, piece(at: twoStep) == nil {
                moves.append(twoStep)
            }
        }

        let captureTargets = [
            Position(row: from.row + direction, col: from.col - 1),
            Position(row: from.row + direction, col: from.col + 1)
        ]
        for target in captureTargets where target.isValid {
            if let targetPiece = piece(at: target), targetPiece.color != color {
                moves.append(target)
            }
        }
        return moves
    }

    func isSquareAttacked(_ target: Position, by color: PieceColor) -> Bool {
        for row in 0..<8 {
            for col in 0..<8 {
                let from = Position(row: row, col: col)
                guard let piece = piece(at: from), piece.color == color else { continue }
                let attacks: [Position]
                if piece.type == .pawn {
                    let dir = color == .white ? -1 : 1
                    attacks = [
                        Position(row: from.row + dir, col: from.col - 1),
                        Position(row: from.row + dir, col: from.col + 1)
                    ].filter(\.isValid)
                } else {
                    attacks = pseudoLegalMoves(from: from, piece: piece)
                }
                if attacks.contains(target) {
                    return true
                }
            }
        }
        return false
    }

    func allLegalMoves(for color: PieceColor) -> [(Position, Position)] {
        var moves: [(Position, Position)] = []
        for row in 0..<8 {
            for col in 0..<8 {
                let from = Position(row: row, col: col)
                guard let piece = piece(at: from), piece.color == color else { continue }
                for to in legalMoves(from: from, color: color) {
                    moves.append((from, to))
                }
            }
        }
        return moves
    }
}
