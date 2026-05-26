import SwiftData
import SwiftUI

struct CoordinateSelectionView: View {
    @Bindable private var viewModel: CoordinateSelectionViewModel

    init(viewModel: CoordinateSelectionViewModel = CoordinateSelectionViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            CoordinateSearchPanel(viewModel: viewModel)
                .zIndex(1)

            CoordinateFieldsView(viewModel: viewModel)

            RecentCoordinatesView(onSelect: viewModel.selectRecentCoordinate)

            CoordinateMapView(viewModel: viewModel)
                .frame(maxWidth: .infinity, minHeight: AppDesign.Layout.mapMinimumHeight, maxHeight: .infinity)
                .layoutPriority(1)
        }
        .padding(AppDesign.Spacing.lg)
        .background(.background)
    }
}

#Preview {
    CoordinateSelectionView(viewModel: CoordinateSelectionViewModel())
        .frame(width: 520, height: 620)
        .modelContainer(for: [RecentCoordinate.self, BatchRunSummary.self], inMemory: true)
}
