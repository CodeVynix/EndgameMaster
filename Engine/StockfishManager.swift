import Foundation

final class StockfishManager {
    
    static let shared = StockfishManager()
    
    private init() {}
    
    // MARK: - Public API
    
    /// Get best move (TEMP placeholder so app builds)
    func getBestMove(fen: String, completion: @escaping (String?) -> Void) {
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            
            // Simple fallback moves (keeps app functional)
            let moves = [
                "e2e4", "d2d4", "g1f3", "c2c4",
                "e7e5", "d7d5", "g8f6", "c7c5"
            ]
            
            let move = moves.randomElement()
            
            DispatchQueue.main.async {
                completion(move)
            }
        }
    }
    
    // MARK: - Optional helpers
    
    func isMoveValid(_ move: String) -> Bool {
        return move.count == 4 || move.count == 5
    }
    
    func reset() {
        // No-op for now
    }
}