import SwiftUI

struct ReservedLocationPanel: View {
    var body: some View {
        VStack(spacing: AppDesign.Spacing.md) {
            Spacer()

            Image(systemName: "location.slash")
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: AppDesign.Spacing.sm) {
                Text("Location selection comes next")
                    .font(.headline)
                    .bold()

                Text("Phase 1 is focused on building a reliable file set.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }

            Spacer()
        }
        .padding(AppDesign.Spacing.xl)
        .background(.background)
    }
}
