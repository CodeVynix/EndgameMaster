import Foundation

final class StockfishManager {
    
    static let shared = StockfishManager()
    
    private init() {}
    
    func bestMove(fen: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            
            let result = fen.withCString { cString in
                sf_best_move(cString)
            }
            
            let move = result != nil ? String(cString: result!) : nil
            
            DispatchQueue.main.async {
                completion(move)
            }
        }
    }
}