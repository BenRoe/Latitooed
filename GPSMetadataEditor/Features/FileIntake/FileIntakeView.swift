import SwiftUI

struct FileIntakeView: View {
    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                    VStack(spacing: AppDesign.Spacing.lg) {
                        Image(systemName: "photo.stack")
                            .imageScale(.large)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)

                        VStack(spacing: AppDesign.Spacing.sm) {
                            Text("Drop media files here")
                                .font(.title2)
                                .bold()

                            Text("Add JPEG, HEIC, MOV, or MP4 files to review them before choosing a location.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .textSelection(.enabled)
                        }

                        Button("Add Files", systemImage: "plus", action: {})
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .frame(minHeight: AppDesign.Layout.minimumControlHeight)

                        Text("Drop more files here or add files from Finder.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: AppDesign.Layout.dropZoneMinimumHeight)
                    .padding(AppDesign.Spacing.xl)
                    .background(.background)
                    .overlay {
                        RoundedRectangle(cornerSize: AppDesign.Radius.largeSize)
                            .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
                    }
                    .clipShape(.rect(cornerSize: AppDesign.Radius.largeSize))
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                        HStack {
                            Text("Selected Files")
                                .font(.headline)
                                .bold()

                            Spacer()

                            Text("0 files")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: AppDesign.Spacing.md, verticalSpacing: AppDesign.Spacing.sm) {
                            GridRow {
                                Text("Display Name")
                                Text("Type")
                                Text("GPS")
                                Text("Latest Result")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Divider()
                                .gridCellColumns(4)

                            GridRow {
                                Text("No files selected")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .gridCellColumns(4)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppDesign.Spacing.md)
                        .background(.background)
                        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))

                        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                            Label("Ready for supported media files", systemImage: "checkmark.circle")
                                .font(.body)
                                .foregroundStyle(.secondary)

                            Text("Not checked")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("Pending")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppDesign.Spacing.md)
                        .background(.background)
                        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
                    }
                }
                .frame(minWidth: AppDesign.Layout.leftColumnMinimumWidth, idealWidth: AppDesign.Layout.leftColumnIdealWidth)
                .padding(AppDesign.Spacing.lg)

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
                .frame(minWidth: AppDesign.Layout.rightColumnMinimumWidth, maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppDesign.Spacing.xl)
                .background(.background)
            }

            Divider()

            HStack(spacing: AppDesign.Spacing.sm) {
                Label("Ready", systemImage: "tray")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Add files to start the intake review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(height: AppDesign.Layout.footerHeight)
            .padding(.horizontal, AppDesign.Spacing.lg)
        }
        .frame(minWidth: AppDesign.Layout.minimumWindowWidth, minHeight: AppDesign.Layout.minimumWindowHeight)
    }
}

#Preview {
    FileIntakeView()
}
