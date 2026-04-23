import Foundation

class StockfishManager {
    
    static let shared = StockfishManager()
    
    private init() {}
    
    // MARK: - Send command to Stockfish (C bridge)
    private func sendCommand(_ command: String) {
        command.withCString { cString in
            sf_send_command(cString)
        }
    }
    
    // MARK: - Get best move
    func bestMove(fen: String, completion: @escaping (String?) -> Void) {
        fen.withCString { cString in
            if let result = sf_best_move(cString) {
                let move = String(cString: result)
                completion(move)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - Set ELO (100 → 2800)
    func setElo(_ elo: Int) {
        let clamped = max(100, min(elo, 2800))
        
        sendCommand("setoption name UCI_LimitStrength value true")
        sendCommand("setoption name UCI_Elo value \(clamped)")
    }
}