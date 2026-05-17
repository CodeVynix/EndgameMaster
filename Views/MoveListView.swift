import SwiftUI

struct MoveListView: View {
    @ObservedObject var vm: GameViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(0..<vm.moveHistory.count, id: \.self) { i in
                    
                    let move = vm.moveHistory[i]
                    
                    Text("\(i+1). \(move.notation)")
                        .font(.system(size: 14))
                        .padding(4)
                        .background(vm.currentMoveIndex == i+1 ? Color.yellow.opacity(0.4) : Color.clear)
                        .onTapGesture {
                            vm.goToMove(i+1)
                        }
                }
            }
        }
        .frame(width: 120)
    }
}
