import SwiftUI

struct AnalysisView: View {
    var lines: [String]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(lines.prefix(3), id: \.self) { move in
                Text(move)
                    .font(.caption)
            }
        }
        .padding()
    }
}
