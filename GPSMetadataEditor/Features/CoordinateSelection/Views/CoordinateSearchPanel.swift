import SwiftUI

struct CoordinateSearchPanel: View {
    @Bindable var viewModel: CoordinateSelectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack(spacing: AppDesign.Spacing.sm) {
                TextField("Search for a place", text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.performSearchOnSubmit()
                    }

                Button("Search", systemImage: "magnifyingglass", action: viewModel.search)
                    .disabled(viewModel.isSearchButtonDisabled)
            }

            if viewModel.isSearchResultsExpanded {
                VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                    Text("Results")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if viewModel.searchStatus == .searching {
                        ProgressView()
                            .controlSize(.small)
                    }

                    if let statusText = viewModel.searchStatusText {
                        Text(statusText)
                            .font(.caption)
                            .foregroundStyle(viewModel.searchStatus == .failed ? .orange : .secondary)
                    }

                    ForEach(viewModel.searchResults) { result in
                        Button {
                            viewModel.selectSearchResult(result)
                        } label: {
                            CoordinateSearchResultRow(result: result)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppDesign.Spacing.sm)
                .background(.regularMaterial)
                .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
            }
        }
    }
}

private struct CoordinateSearchResultRow: View {
    let result: CoordinateSearchResult

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "mappin.circle")
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
                Text(result.title)
                    .font(.body)
                    .foregroundStyle(.primary)

                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(AppDesign.Spacing.sm)
        .contentShape(.rect)
    }
}
