import Foundation

final class ProgressManager {
    static let shared = ProgressManager()

    private let completedKey = "endgame_master_completed_puzzles"
    private let defaults = UserDefaults.standard

    private init() {}

    var completedPuzzleIDs: Set<String> {
        get {
            let values = defaults.array(forKey: completedKey) as? [String] ?? []
            return Set(values)
        }
        set {
            defaults.set(Array(newValue), forKey: completedKey)
        }
    }

    func markCompleted(_ puzzleID: UUID) {
        var values = completedPuzzleIDs
        values.insert(puzzleID.uuidString)
        completedPuzzleIDs = values
    }

    func isCompleted(_ puzzleID: UUID) -> Bool {
        completedPuzzleIDs.contains(puzzleID.uuidString)
    }
}
