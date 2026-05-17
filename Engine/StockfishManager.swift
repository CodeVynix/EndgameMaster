func bestMove(fen: String, completion: @escaping (String?) -> Void) {
    DispatchQueue.global().async {
        fen.withCString { cString in
            if let result = sf_best_move(cString) {
                let move = String(cString: result)
                DispatchQueue.main.async {
                    completion(move)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
