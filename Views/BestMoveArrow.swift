import SwiftUI

struct BestMoveArrow: View {
    let move: String?
    
    var body: some View {
        GeometryReader { geo in
            if let move = move, move.count >= 4 {
                let from = squareToPoint(String(move.prefix(2)), geo)
                let to = squareToPoint(String(move.suffix(2)), geo)
                
                Path { path in
                    path.move(to: from)
                    path.addLine(to: to)
                }
                .stroke(Color.green, lineWidth: 4)
            }
        }
    }
    
    func squareToPoint(_ sq: String, _ geo: GeometryProxy) -> CGPoint {
        let files = "abcdefgh"
        let file = files.firstIndex(of: sq.first!)!
        let rank = Int(String(sq.last!))!
        
        let x = CGFloat(files.distance(from: files.startIndex, to: file)) / 8 * geo.size.width
        let y = CGFloat(8 - rank) / 8 * geo.size.height
        
        return CGPoint(x: x, y: y)
    }
}
