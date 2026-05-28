import SwiftUI

struct CoordinateSearchPanel: View {
    @Bindable var viewModel: CoordinateSelectionViewModel

    @State private var debounceTask: Task<Void, Never>?
    @State private var isDropdownVisible = false
    @State private var fieldHeight: CGFloat = 28

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack(spacing: AppDesign.Spacing.sm) {
                TextField("Search for a place", text: $viewModel.searchQuery)
                    .textFieldStyle(.roundedBorder)
                    .overlay(alignment: .trailing) {
                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.searchQuery = ""
                                debounceTask?.cancel()
                                viewModel.cancelSearch()
                                isDropdownVisible = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Clear search field")
                            .padding(.trailing, AppDesign.Spacing.xs)
                        }
                    }
                    .onExitCommand {
                        viewModel.searchQuery = ""
                        debounceTask?.cancel()
                        viewModel.cancelSearch()
                        isDropdownVisible = false
                    }
            }
            .onChange(of: viewModel.searchQuery) { _, newValue in
                debounceTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.count >= 3 else {
                    viewModel.cancelSearch()
                    viewModel.clearSearch()
                    isDropdownVisible = false
                    return
                }
                isDropdownVisible = true
                debounceTask = Task { @MainActor in
                    do {
                        try await Task.sleep(for: .milliseconds(500))
                    } catch {
                        return
                    }
                    viewModel.search()
                }
            }
            .onChange(of: viewModel.isSearchResultsExpanded) { _, newValue in
                if !newValue { isDropdownVisible = false }
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fieldHeight = $0 }
            .overlay(alignment: .top) {
                if isDropdownVisible {
                    SearchDropdownView(viewModel: viewModel, onDismiss: { isDropdownVisible = false })
                        .offset(y: fieldHeight)
                }
            }
            .onDisappear {
                debounceTask?.cancel()
            }
        }
    }
}

private struct SearchDropdownView: View {
    let viewModel: CoordinateSelectionViewModel
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("Results")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.searchStatus == .searching {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Searching")
            }

            if let statusText = viewModel.searchStatusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(viewModel.searchStatus == .failed ? .orange : .secondary)
            }

            if !viewModel.searchResults.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(viewModel.searchResults) { result in
                            Button {
                                viewModel.selectSearchResult(result)
                                onDismiss()
                            } label: {
                                CoordinateSearchResultRow(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(height: 240)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppDesign.Spacing.sm)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: AppDesign.Radius.medium))
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .contain)
    }
}

private struct CoordinateSearchResultRow: View {
    let result: CoordinateSearchResult
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
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
        .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(.rect(cornerRadius: 6))
        .contentShape(.rect)
        .onHover { isHovered = $0 }
    }
}
