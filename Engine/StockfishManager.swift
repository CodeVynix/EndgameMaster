import Foundation

final class StockfishManager {

    init() {
        StockfishWrapper.shared().initializeEngine()
    }

    func bestMove(for fen: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async {
            let move = StockfishWrapper.shared().getBestMove(fen)
            DispatchQueue.main.async {
                completion(move)
            }
        }
    }
}