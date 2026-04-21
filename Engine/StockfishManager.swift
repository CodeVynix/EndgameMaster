import Foundation

class StockfishManager {

    static let shared = StockfishManager()

    private init() {}

    func bestMove(for fen: String, completion: @escaping (String?) -> Void) {
        DispatchQueue.global().async {
            let cString = fen.cString(using: .utf8)
            let result = get_best_move(cString)

            let move = result != nil ? String(cString: result!) : nil

            DispatchQueue.main.async {
                completion(move)
            }
        }
    }
}