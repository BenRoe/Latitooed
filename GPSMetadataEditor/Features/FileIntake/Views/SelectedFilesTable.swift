import SwiftUI

struct SelectedFilesTable: View {
    let files: [SelectedMediaFile]
    @Binding var selection: SelectedMediaFile.ID?

    var body: some View {
        if files.isEmpty {
            Text("No files selected")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
        } else {
            Table(files, selection: $selection) {
                TableColumn("Display Name") { file in
                    Text(file.displayName)
                        .lineLimit(1)
                        .help(file.displayName)
                }

                TableColumn("Type") { file in
                    TypeBadge(kind: file.kind)
                }
                .width(min: 72, ideal: 80, max: 96)

                TableColumn("GPS") { file in
                    GPSStatusCell(status: file.gpsStatus)
                }
                .width(min: 116, ideal: 128, max: 144)

                TableColumn("Latest Result") { file in
                    LatestResultCell(status: file.latestResult)
                }
                .width(min: 120, ideal: 136, max: 160)
            }
            .frame(minHeight: 220)
        }
    }
}

private struct TypeBadge: View {
    let kind: MediaFileKind

    var body: some View {
        Text(kind.displayName)
            .font(.caption)
            .padding(.horizontal, AppDesign.Spacing.sm)
            .padding(.vertical, AppDesign.Spacing.xs)
            .background(.quaternary)
            .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
            .accessibilityLabel("File type \(kind.displayName)")
    }
}

private struct GPSStatusCell: View {
    let status: GPSStatus

    var body: some View {
        Label(status.displayName, systemImage: "location.slash")
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.secondary)
    }
}

private struct LatestResultCell: View {
    let status: FileResultStatus

    var body: some View {
        Label(status.displayName, systemImage: "clock")
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.secondary)
    }
}
