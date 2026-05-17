import Foundation

class OpeningManager {
    
    static let shared = OpeningManager()
    
    private var data: [String: [String: String]] = [:]
    
    init() {
        load()
    }
    
    private func load() {
        guard let url = Bundle.main.url(forResource: "openings", withExtension: "json"),
              let d = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String: String]].self, from: d) else {
            return
        }
        
        data = decoded
    }
    
    func moves(for fen: String) -> [String: String] {
        return data[fen] ?? [:]
    }
}
