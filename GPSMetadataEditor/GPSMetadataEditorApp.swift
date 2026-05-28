import SwiftData
import SwiftUI

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [RecentCoordinate.self, BatchRunSummary.self] }
}

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}

@main
struct GPSMetadataEditorApp: App {
    let container: ModelContainer = {
        let schema = Schema([RecentCoordinate.self, BatchRunSummary.self])
        do {
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            FileIntakeView()
        }
        .modelContainer(container)
    }
}
