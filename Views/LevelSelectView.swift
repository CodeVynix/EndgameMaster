import SwiftUI

struct LevelSelectView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(PuzzleDifficulty.allCases, id: \.self) { difficulty in
                    Section(difficulty.rawValue) {
                        ForEach(viewModel.groupedPuzzles[difficulty] ?? []) { puzzle in
                            Button {
                                viewModel.loadPuzzle(puzzle)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(puzzle.title)
                                            .font(.headline)
                                        Text(puzzle.fen)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if ProgressManager.shared.isCompleted(puzzle.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Level")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
