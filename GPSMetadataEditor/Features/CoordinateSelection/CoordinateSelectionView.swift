import SwiftUI

struct CoordinateSelectionView: View {
    @State private var viewModel = CoordinateSelectionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            CoordinateSearchPanel(viewModel: viewModel)

            CoordinateFieldsView(viewModel: viewModel)

            CoordinateMapView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(AppDesign.Spacing.lg)
        .background(.background)
    }
}

#Preview {
    CoordinateSelectionView()
        .frame(width: 520, height: 620)
}
