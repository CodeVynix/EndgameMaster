import Foundation
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var board = ChessBoard()
    @Published var gameState = GameState()
    @Published var selectedPosition: Position?
    @Published var legalMoves: [Position] = []
    @Published var currentPuzzle: Puzzle?
    @Published var puzzleMoveIndex: Int = 0
    @Published var aiElo: Double = 1200
    @Published var isThinking: Bool = false
    @Published var showLevelSelect: Bool = false

    let stockfish = StockfishManager.shared
    let puzzles: [Puzzle] = PuzzleLibrary.all

    init() {
        loadPuzzle(puzzles.first ?? PuzzleLibrary.fallback)
    }

    var groupedPuzzles: [PuzzleDifficulty: [Puzzle]] {
        Dictionary(grouping: puzzles, by: \.difficulty)
    }

    var completedCount: Int {
        puzzles.filter { ProgressManager.shared.isCompleted($0.id) }.count
    }

    func newPuzzle() {
        let unsolved = puzzles.filter { !ProgressManager.shared.isCompleted($0.id) }
        loadPuzzle((unsolved.isEmpty ? puzzles : unsolved).randomElement() ?? PuzzleLibrary.fallback)
    }

    func nextLevel() {
        guard let currentPuzzle else {
            newPuzzle()
            return
        }

        let sameDifficulty = puzzles
            .filter { $0.difficulty == currentPuzzle.difficulty }
            .sorted { $0.title < $1.title }

        guard let idx = sameDifficulty.firstIndex(of: currentPuzzle) else {
            newPuzzle()
            return
        }

        let nextIdx = sameDifficulty.index(after: idx)
        if nextIdx < sameDifficulty.endIndex {
            loadPuzzle(sameDifficulty[nextIdx])
        } else {
            if let upgraded = nextDifficulty(from: currentPuzzle.difficulty),
               let nextPuzzle = groupedPuzzles[upgraded]?.first {
                loadPuzzle(nextPuzzle)
            } else {
                loadPuzzle(sameDifficulty[idx])
            }
        }
    }

    func setAiElo(_ value: Double) {
        aiElo = value
        stockfish.setElo(Int(value))
    }

    func selectSquare(_ position: Position) {
        guard let piece = board.piece(at: position), piece.color == gameState.currentTurn else {
            selectedPosition = nil
            legalMoves = []
            return
        }

        selectedPosition = position
        legalMoves = board.legalMoves(from: position, color: gameState.currentTurn)
    }

    func attemptMove(to target: Position) {
        guard let source = selectedPosition else { return }
        makeMove(from: source, to: target)
    }

    func makeMove(from: Position, to: Position) {
        guard let piece = board.piece(at: from), piece.color == gameState.currentTurn else {
            resetSelection()
            return
        }

        guard let result = board.move(from: from, to: to, color: gameState.currentTurn) else {
            resetSelection()
            return
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            SoundManager.shared.playMove(didCapture: result.didCapture)
            resetSelection()
        }

        if gameState.mode == .puzzle {
            validatePuzzleMove(from: from, to: to)
        } else {
            advanceTurnAndStatus()
            requestAiMoveIfNeeded()
        }
    }

    func switchToAIMode() {
        gameState.mode = .aiMatch
        gameState.statusMessage = "Your turn"
        board.loadStandardPosition()
        gameState.currentTurn = .white
        resetSelection()
    }

    func loadPuzzle(_ puzzle: Puzzle) {
        currentPuzzle = puzzle
        puzzleMoveIndex = 0
        gameState.mode = .puzzle
        gameState.currentTurn = .white
        gameState.statusMessage = puzzle.title
        gameState.isSolved = false
        gameState.isCheckmate = false
        board.loadFEN(puzzle.fen)
        resetSelection()
    }

    private func validatePuzzleMove(from: Position, to: Position) {
        guard let currentPuzzle else { return }
        guard puzzleMoveIndex < currentPuzzle.solution.count else { return }

        let expected = currentPuzzle.solution[puzzleMoveIndex]
        let played = "\(from.algebraic)\(to.algebraic)"
        if played == expected {
            puzzleMoveIndex += 1
            if puzzleMoveIndex >= currentPuzzle.solution.count {
                gameState.statusMessage = "Solved! 🎉"
                gameState.isSolved = true
                ProgressManager.shared.markCompleted(currentPuzzle.id)
                return
            }
            gameState.currentTurn = gameState.currentTurn.opposite
            gameState.statusMessage = "Good move! Keep going."
        } else {
            gameState.statusMessage = "Try again"
            board.loadFEN(currentPuzzle.fen)
            puzzleMoveIndex = 0
            gameState.currentTurn = .white
        }
        updateCheckStatus()
    }

    private func requestAiMoveIfNeeded() {
        guard gameState.mode == .aiMatch, gameState.currentTurn == .black else { return }
        isThinking = true
        gameState.statusMessage = "AI is thinking..."

        let fen = board.generateFEN(activeColor: .black)
        stockfish.bestMove(fen: fen) { [weak self] bestMove in
            guard let self else { return }
            self.isThinking = false
            guard let bestMove,
                  let parsed = ChessBoard.parseMove(bestMove),
                  self.board.isLegalMove(from: parsed.from, to: parsed.to, color: .black),
                  let result = self.board.move(from: parsed.from, to: parsed.to, color: .black) else {
                self.gameState.statusMessage = "AI move unavailable"
                return
            }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                SoundManager.shared.playMove(didCapture: result.didCapture)
            }
            self.advanceTurnAndStatus()
        }
    }

    private func advanceTurnAndStatus() {
        gameState.currentTurn = gameState.currentTurn.opposite
        updateCheckStatus()

        if board.isCheckmate(color: gameState.currentTurn) {
            gameState.isCheckmate = true
            gameState.statusMessage = "Checkmate! You win 🎉"
        } else if board.isKingInCheck(color: gameState.currentTurn) {
            gameState.statusMessage = "Check"
        } else {
            gameState.statusMessage = gameState.currentTurn == .white ? "Your turn" : "AI turn"
        }
    }

    private func updateCheckStatus() {
        if board.isCheckmate(color: gameState.currentTurn) {
            gameState.statusMessage = "Checkmate! You win 🎉"
            gameState.isCheckmate = true
        } else if board.isKingInCheck(color: gameState.currentTurn) {
            gameState.statusMessage = "Check"
        } else {
            gameState.isCheckmate = false
        }
    }

    private func nextDifficulty(from current: PuzzleDifficulty) -> PuzzleDifficulty? {
        switch current {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return nil
        }
    }

    private func resetSelection() {
        selectedPosition = nil
        legalMoves = []
    }
}

enum PuzzleLibrary {
    static let fallback = Puzzle(
        title: "Fallback Mate",
        fen: "6k1/5ppp/8/8/8/5Q2/6PP/6K1 w - - 0 1",
        solution: ["f3a8"],
        difficulty: .beginner
    )

    static let all: [Puzzle] = [
        Puzzle(title: "Mate in One #1", fen: "6k1/5ppp/8/8/8/5Q2/6PP/6K1 w - - 0 1", solution: ["f3a8"], difficulty: .beginner),
        Puzzle(title: "Mate in One #2", fen: "k7/8/1KQ5/8/8/8/8/8 w - - 0 1", solution: ["c6a8"], difficulty: .beginner),
        Puzzle(title: "Simple Fork", fen: "4k3/8/8/3N4/8/8/8/4K3 w - - 0 1", solution: ["d5f6"], difficulty: .beginner),
        Puzzle(title: "Rook Finish", fen: "6k1/8/8/8/8/8/6R1/6K1 w - - 0 1", solution: ["g2a2"], difficulty: .beginner),
        Puzzle(title: "Queen Net", fen: "4k3/8/8/8/8/2Q5/8/4K3 w - - 0 1", solution: ["c3c8"], difficulty: .intermediate),
        Puzzle(title: "Bishop Strike", fen: "4k3/8/8/3B4/8/8/8/4K3 w - - 0 1", solution: ["d5c6"], difficulty: .intermediate),
        Puzzle(title: "Knight Pressure", fen: "4k3/8/8/8/3N4/8/8/4K3 w - - 0 1", solution: ["d4f5"], difficulty: .intermediate),
        Puzzle(title: "Rook Lift", fen: "4k3/8/8/8/8/8/4R3/4K3 w - - 0 1", solution: ["e2e8"], difficulty: .intermediate),
        Puzzle(title: "Advanced Mate #1", fen: "6k1/5ppp/8/8/8/6Q1/6PP/6K1 w - - 0 1", solution: ["g3b8"], difficulty: .advanced),
        Puzzle(title: "Advanced Mate #2", fen: "k7/8/1K6/2Q5/8/8/8/8 w - - 0 1", solution: ["c5a7"], difficulty: .advanced)
    ]
}
