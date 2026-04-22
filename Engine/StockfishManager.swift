import Foundation

final class StockfishManager {
    
    static let shared = StockfishManager()
    
    private init() {}
    
    private let queue = DispatchQueue(label: "stockfish.queue", qos: .userInitiated)

    func bestMove(fen: String, completion: @escaping (String?) -> Void) {
        queue.async {
            guard let cString = fen.cString(using: .utf8) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            guard let result = sf_best_move(cString) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            let move = String(cString: result)

            DispatchQueue.main.async {
                completion(move)
            }
        }
    }
}