import Foundation
import SwiftUI

class GameViewModel: ObservableObject {
    
    @Published var board = ChessBoard()
    
    // MARK: Engine
    @Published var eval: Double = 0
    @Published var bestMove: String?
    @Published var pv: [String] = []
    
    // MARK: Hint UI
    @Published var hintMove: (Int, Int)?
    
    // MARK: Puzzle Mode
    @Published var isPuzzleMode = false
    @Published var puzzleMoves: [String] = []
    @Published var puzzleIndex = 0
    
    private let engine = StockfishManager.shared
    
    // MARK: Play move
    
    func playMove(_ move: Move) {
        withAnimation(.easeInOut(duration: 0.25)) {
            board.makeMove(move)
        }
        
        SoundManager.shared.move()
        
        if isPuzzleMode {
            checkPuzzleMove(move.toUCI())
        } else {
            analyze()
        }
    }
    
    // MARK: Engine
    
    func analyze() {
        let fen = board.toFEN()
        
        engine.start(fen: fen) { eval, _, _, _, best, pv in
            self.eval = eval
            self.bestMove = best
            self.pv = pv
            
            self.updateHint()
        }
    }
    
    func stop() {
        engine.stop()
    }
    
    // MARK: Hint
    
    func updateHint() {
        guard let best = bestMove, best.count >= 4 else { return }
        
        let from = squareIndex(from: String(best.prefix(2)))
        let to = squareIndex(from: String(best.suffix(2)))
        
        hintMove = (from, to)
    }
    
    // MARK: Puzzle
    
    func startPuzzle() {
        guard let puzzle = PuzzleManager.shared.next() else { return }
        
        board.loadFEN(puzzle.fen)
        puzzleMoves = puzzle.solution
        puzzleIndex = 0
        isPuzzleMode = true
    }
    
    func checkPuzzleMove(_ move: String) {
        guard puzzleIndex < puzzleMoves.count else { return }
        
        if move == puzzleMoves[puzzleIndex] {
            puzzleIndex += 1
            SoundManager.shared.move()
            
            if puzzleIndex == puzzleMoves.count {
                print("Puzzle solved 🎉")
            }
        } else {
            SoundManager.shared.illegal()
        }
    }
    
    // MARK: Helpers
    
    func squareIndex(from algebraic: String) -> Int {
        let file = Int(algebraic.first!.asciiValue! - Character("a").asciiValue!)
        let rank = Int(algebraic.last!.asciiValue! - Character("1").asciiValue!)
        return rank * 8 + file
    }
}

// ADD THIS INSIDE CLASS

func playMove(from: Position, to: Position) {
    
    if let _ = board.makeMove(from: from, to: to) {
        SoundManager.shared.move()
        analyze()
    } else {
        SoundManager.shared.illegal()
    }
}

// REPLACE updateHint()

func updateHint() {
    guard let best = bestMove, best.count >= 4 else { return }
    
    let fromStr = String(best.prefix(2))
    let toStr = String(best.suffix(2))
    
    let from = squareIndex(from: fromStr)
    let to = squareIndex(from: toStr)
    
    hintMove = (from, to)
}
