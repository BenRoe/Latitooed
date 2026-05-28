import AppKit
import SwiftUI

struct SelectedFilesTable: View {
    let files: [SelectedMediaFile]
    @Binding var selection: Set<SelectedMediaFile.ID>

    var body: some View {
        if files.isEmpty {
            ContentUnavailableView("No Files Selected", systemImage: "tray")
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
            .background(TableSelectionNormalizer(files: files, selection: $selection))
        }
    }
}

private struct TableSelectionNormalizer: NSViewRepresentable {
    let files: [SelectedMediaFile]
    @Binding var selection: Set<SelectedMediaFile.ID>

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.view = view
        context.coordinator.installMonitor()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.view = nsView
        context.coordinator.files = files
        context.coordinator.selection = $selection
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(files: files, selection: $selection)
    }

    final class Coordinator {
        var files: [SelectedMediaFile]
        var selection: Binding<Set<SelectedMediaFile.ID>>
        weak var view: NSView?
        private var monitor: Any?

        init(files: [SelectedMediaFile], selection: Binding<Set<SelectedMediaFile.ID>>) {
            self.files = files
            self.selection = selection
        }

        func installMonitor() {
            guard monitor == nil else {
                return
            }

            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                self?.handleMouseDown(event)
                return event
            }
        }

        func removeMonitor() {
            guard let monitor else {
                return
            }

            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }

        private func handleMouseDown(_ event: NSEvent) {
            let modifierFlags = event.modifierFlags
            guard modifierFlags.contains(.command) == false,
                  modifierFlags.contains(.shift) == false,
                  let view,
                  let window = view.window,
                  event.window === window,
                  let contentView = window.contentView else {
                return
            }

            let contentPoint = contentView.convert(event.locationInWindow, from: nil)
            guard let tableView = contentView.hitTest(contentPoint)?.enclosingTableView else {
                return
            }

            let tablePoint = tableView.convert(event.locationInWindow, from: nil)
            let row = tableView.row(at: tablePoint)
            guard files.indices.contains(row) else {
                return
            }

            let selectedID = files[row].id
            Task { @MainActor in
                await Task.yield()
                selection.wrappedValue = [selectedID]
            }
        }
    }
}

private extension NSView {
    var enclosingTableView: NSTableView? {
        if let tableView = self as? NSTableView {
            return tableView
        }

        return superview?.enclosingTableView
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
            .clipShape(.rect(cornerRadius: AppDesign.Radius.small))
            .accessibilityLabel("File type \(kind.displayName)")
    }
}

private struct GPSStatusCell: View {
    let status: GPSStatus

    var body: some View {
        Label(status.displayName, systemImage: status.systemImage)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.secondary)
    }
}

private struct LatestResultCell: View {
    let status: FileResultStatus

    var body: some View {
        Label(status.displayName, systemImage: status.systemImage)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.secondary)
    }
}
