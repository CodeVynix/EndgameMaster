import SwiftUI

struct ContentView: View {
    
    @StateObject var vm = GameViewModel()
    @State private var mode = 0
    
    var body: some View {
        VStack {
            
            Picker("", selection: $mode) {
                Text("Play").tag(0)
                Text("Analysis").tag(1)
                Text("Puzzles").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if mode == 0 {
                ChessBoardView(viewModel: vm)
            }
            
            if mode == 1 {
                VStack {
                    ChessBoardView(viewModel: vm)
                    Button("Analyze") { vm.analyze() }
                }
            }
            
            if mode == 2 {
                VStack {
                    ChessBoardView(viewModel: vm)
                    Button("Next Puzzle") {
                        vm.startPuzzle()
                    }
                }
            }
        }
    }
}
