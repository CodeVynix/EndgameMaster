import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.2),
                    Color(red: 0.14, green: 0.2, blue: 0.32),
                    Color(red: 0.1, green: 0.16, blue: 0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    ChessBoardView(viewModel: viewModel)
                        .frame(maxWidth: 500)
                    controlsCard
                    aiCard
                }
                .padding()
            }
        }
        .sheet(isPresented: $viewModel.showLevelSelect) {
            LevelSelectView(viewModel: viewModel)
        }
    }

    private var headerCard: some View {
        VStack(spacing: 8) {
            Text("Endgame Master")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(viewModel.gameState.statusMessage)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Completed: \(viewModel.completedCount)/\(viewModel.puzzles.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
    }

    private var controlsCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Button("New Puzzle") {
                    withAnimation(.spring()) {
                        viewModel.newPuzzle()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Next Level") {
                    withAnimation(.spring()) {
                        viewModel.nextLevel()
                    }
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                Button("Select Level") {
                    viewModel.showLevelSelect = true
                }
                .buttonStyle(.bordered)

                Button("AI Match") {
                    withAnimation(.spring()) {
                        viewModel.switchToAIMode()
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var aiCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI Difficulty")
                .font(.headline)
            HStack {
                Slider(
                    value: Binding(
                        get: { viewModel.aiElo },
                        set: { viewModel.setAiElo($0) }
                    ),
                    in: 400...2500,
                    step: 50
                )
                Text("\(Int(viewModel.aiElo)) ELO")
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 95, alignment: .trailing)
            }
            if viewModel.isThinking {
                ProgressView("AI calculating...")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}
