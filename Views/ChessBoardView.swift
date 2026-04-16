import SwiftUI

struct ChessBoardView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            let squareSize = side / 8

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { col in
                                let position = Position(row: row, col: col)
                                SquareView(
                                    position: position,
                                    piece: viewModel.board.piece(at: position),
                                    isLight: (row + col) % 2 == 0,
                                    isSelected: viewModel.selectedPosition == position,
                                    isLegalMove: viewModel.legalMoves.contains(position),
                                    size: squareSize
                                )
                                .frame(width: squareSize, height: squareSize)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    handleTap(position)
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 6)
                                        .onEnded { value in
                                            handleDrag(from: position, value: value, squareSize: squareSize)
                                        }
                                )
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(10)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func handleTap(_ position: Position) {
        if viewModel.selectedPosition == nil {
            viewModel.selectSquare(position)
        } else if viewModel.legalMoves.contains(position) {
            viewModel.attemptMove(to: position)
        } else {
            viewModel.selectSquare(position)
        }
    }

    private func handleDrag(from source: Position, value: DragGesture.Value, squareSize: CGFloat) {
        guard viewModel.selectedPosition == source || viewModel.board.piece(at: source)?.color == viewModel.gameState.currentTurn else {
            return
        }

        viewModel.selectSquare(source)
        let deltaCol = Int((value.translation.width / squareSize).rounded())
        let deltaRow = Int((value.translation.height / squareSize).rounded())
        let target = Position(row: source.row + deltaRow, col: source.col + deltaCol)

        guard target.isValid else {
            return
        }
        if viewModel.legalMoves.contains(target) {
            viewModel.makeMove(from: source, to: target)
        }
    }
}
