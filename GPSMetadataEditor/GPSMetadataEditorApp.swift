import SwiftData
import SwiftUI

@main
struct GPSMetadataEditorApp: App {
    var body: some Scene {
        WindowGroup {
            FileIntakeView()
        }
        .modelContainer(for: [RecentCoordinate.self, BatchRunSummary.self])
    }
}
