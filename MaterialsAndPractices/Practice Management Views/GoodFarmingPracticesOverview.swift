import SwiftUI

struct GoodFarmingPracticesOverview: View {
    var body: some View {
        List {
            ForEach(GoodFarmingPractices.allCases) { practice in
                Text(practice.name)
            }
        }
    }
}
