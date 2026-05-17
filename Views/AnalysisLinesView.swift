import SwiftUI

struct AnalysisLinesView: View {
    var pv: [String]
    var onTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(pv, id: \.self) { move in
                Text(move)
                    .onTapGesture {
                        onTap(move)
                    }
            }
        }
    }
}
