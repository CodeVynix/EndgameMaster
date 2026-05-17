import Foundation
import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var player: AVAudioPlayer?
    
    private func play(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Missing sound:", name)
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch {
            print("Audio error:", error)
        }
    }
    
    func move() { play("move") }
    func capture() { play("capture") }
    func check() { play("check") }
    func illegal() { play("illegal") }
    func premove() { play("premove") }
    func start() { play("game-start") }
    func checkmate() { play("checkmate") }
}
