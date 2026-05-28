import SwiftUI

struct MapStyleOverlay: View {
    let selectedStyle: MapPresentationStyle
    let selectStyle: (MapPresentationStyle) -> Void

    var body: some View {
        HStack(spacing: AppDesign.Spacing.xs) {
            MapStyleButton(style: .standard, systemImage: "map", isSelected: selectedStyle == .standard, selectStyle: selectStyle)
            MapStyleButton(style: .satellite, systemImage: "globe.americas", isSelected: selectedStyle == .satellite, selectStyle: selectStyle)
            MapStyleButton(style: .hybrid, systemImage: "square.2.layers.3d", isSelected: selectedStyle == .hybrid, selectStyle: selectStyle)
        }
        .padding(AppDesign.Spacing.xs)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: AppDesign.Radius.medium))
    }
}

private struct MapStyleButton: View {
    let style: MapPresentationStyle
    let systemImage: String
    let isSelected: Bool
    let selectStyle: (MapPresentationStyle) -> Void

    var body: some View {
        Button(style.label, systemImage: systemImage) {
            selectStyle(style)
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .foregroundStyle(isSelected ? Color.accentColor : .primary)
        .help(style.label)
    }
}
