import SwiftUI

struct EngineStatsView: View {
    var depth: Int
    var nodes: Int
    var nps: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Depth: \(depth)")
            Text("Nodes: \(nodes)")
            Text("NPS: \(nps)")
        }
        .font(.caption)
    }
}
