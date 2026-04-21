import Foundation

final class StockfishManager {
    
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    
    private let queue = DispatchQueue(label: "stockfish.queue")
    
    init() {
        startEngine()
    }
    
    deinit {
        stopEngine()
    }
    
    // MARK: - Engine Setup
    
    private func startEngine() {
        guard let path = Bundle.main.path(forResource: "stockfish", ofType: nil) else {
            print("❌ Stockfish binary not found")
            return
        }
        
        process = Process()
        inputPipe = Pipe()
        outputPipe = Pipe()
        
        process?.executableURL = URL(fileURLWithPath: path)
        process?.standardInput = inputPipe
        process?.standardOutput = outputPipe
        process?.standardError = outputPipe
        
        do {
            try process?.run()
            sendCommand("uci")
            sendCommand("isready")
        } catch {
            print("❌ Failed to start Stockfish:", error)
        }
    }
    
    private func stopEngine() {
        sendCommand("quit")
        process?.terminate()
        process = nil
    }
    
    // MARK: - Communication
    
    private func sendCommand(_ command: String) {
        guard let data = (command + "\n").data(using: .utf8) else { return }
        inputPipe?.fileHandleForWriting.write(data)
    }
    
    private func readOutput(completion: @escaping (String) -> Void) {
        guard let pipe = outputPipe else { return }
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8) {
                completion(output)
            }
        }
    }
    
    // MARK: - Public API
    
    func bestMove(for fen: String, completion: @escaping (String?) -> Void) {
        queue.async {
            self.sendCommand("position fen \(fen)")
            self.sendCommand("go movetime 1000")
            
            self.waitForBestMove(completion: completion)
        }
    }
    
    private func waitForBestMove(completion: @escaping (String?) -> Void) {
        guard let pipe = outputPipe else {
            completion(nil)
            return
        }
        
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            
            guard let output = String(data: data, encoding: .utf8) else { return }
            
            let lines = output.split(separator: "\n")
            
            for line in lines {
                if line.starts(with: "bestmove") {
                    let parts = line.split(separator: " ")
                    let move = parts.count > 1 ? String(parts[1]) : nil
                    
                    DispatchQueue.main.async {
                        completion(move)
                    }
                    
                    pipe.fileHandleForReading.readabilityHandler = nil
                    return
                }
            }
        }
    }
}