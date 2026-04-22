import Foundation

final class StockfishManager {

    static let shared = StockfishManager()

    private init() {}

    /// Temporary fallback (until native engine is connected)
    func bestMove(fen: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async {
            // Fake move so app works
            let fallbackMoves = ["e2e4", "d2d4", "g1f3", "c2c4"]
            let move = fallbackMoves.randomElement()

            DispatchQueue.main.async {
                completion(move)
            }
        }
    }
}