import SwiftUI

struct ChessBoardView: View {
    
    @ObservedObject var viewModel: GameViewModel
    
    let columns = Array(repeating: GridItem(.flexible()), count: 8)
    
    @State private var selected: Position? = nil
    
    var body: some View {
        ZStack {
            
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(0..<64, id: \.self) { index in
                    
                    let pos = Position(row: 7 - index / 8, col: index % 8)
                    let piece = viewModel.board.piece(at: pos)
                    
                    SquareView(
                        piece: piece,
                        isLight: (index / 8 + index % 8) % 2 == 0,
                        isSelected: selected == pos,
                        isLastMove: false
                    )
                    .onTapGesture {
                        handleTap(pos)
                    }
                }
            }
            
            // Hint arrow (if exists)
            if let hint = viewModel.hintMove {
                HintArrowView(from: hint.0, to: hint.1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding()
    }
    
    // MARK: Tap logic
    
    func handleTap(_ pos: Position) {
        
        if let selected = selected {
            
            if let move = viewModel.board.makeMove(from: selected, to: pos) {
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.board = viewModel.board
                }
                
                SoundManager.shared.move()
                viewModel.analyze()
                
            } else {
                SoundManager.shared.illegal()
            }
            
            self.selected = nil
            
        } else {
            if viewModel.board.piece(at: pos) != nil {
                selected = pos
            }
        }
    }
}
