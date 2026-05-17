import Foundation

class StockfishManager {
    
    static let shared = StockfishManager()
    
    private init() {
        sf_init()
    }
    
    private var running = false
    
    func start(fen: String,
               onUpdate: @escaping (Double, Int, Int, Int, String, [String]) -> Void) {
        
        running = true
        
        fen.withCString { sf_go($0) }
        
        DispatchQueue.global().async {
            while self.running {
                
                let eval = Double(sf_eval()) / 100.0
                let depth = sf_depth()
                let nodes = sf_nodes()
                let nps = sf_nps()
                let best = String(cString: sf_bestmove())
                let pvStr = String(cString: sf_pv())
                
                let pv = pvStr.split(separator: " ").map { String($0) }
                
                DispatchQueue.main.async {
                    onUpdate(eval, depth, nodes, nps, best, pv)
                }
                
                usleep(200000)
            }
        }
    }
    
    func stop() {
        running = false
        sf_stop()
    }
}
