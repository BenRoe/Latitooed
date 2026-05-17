import SwiftUI

struct CoordinateFieldsView: View {
    @Bindable var viewModel: CoordinateSelectionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            HStack(alignment: .top, spacing: AppDesign.Spacing.sm) {
                CoordinateFieldEditor(
                    label: "Latitude",
                    text: $viewModel.latitudeField.text,
                    validationMessage: viewModel.latitudeField.validationMessage,
                    onChange: viewModel.updateLatitude
                )

                CoordinateFieldEditor(
                    label: "Longitude",
                    text: $viewModel.longitudeField.text,
                    validationMessage: viewModel.longitudeField.validationMessage,
                    onChange: viewModel.updateLongitude
                )
            }

            Label(viewModel.readyStatusText, systemImage: viewModel.selectedCoordinate == nil ? "mappin.slash" : "mappin")
                .font(.caption)
                .foregroundStyle(viewModel.selectedCoordinate == nil ? .secondary : .primary)
        }
    }
}

private struct CoordinateFieldEditor: View {
    let label: String
    @Binding var text: String
    let validationMessage: String?
    let onChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField(label, text: $text)
                .textFieldStyle(.roundedBorder)
                .onChange(of: text) { _, newValue in
                    onChange(newValue)
                }

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}
