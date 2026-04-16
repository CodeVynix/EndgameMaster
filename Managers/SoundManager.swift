import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()

    private var movePlayer: AVAudioPlayer?
    private var capturePlayer: AVAudioPlayer?

    private init() {
        movePlayer = makePlayer(fileName: "move", ext: "wav")
        capturePlayer = makePlayer(fileName: "capture", ext: "wav")
    }

    func playMove(didCapture: Bool) {
        if didCapture {
            capturePlayer?.currentTime = 0
            capturePlayer?.play()
        } else {
            movePlayer?.currentTime = 0
            movePlayer?.play()
        }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    private func makePlayer(fileName: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: ext) else { return nil }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            return nil
        }
    }
}
