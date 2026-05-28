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
    var body: some Scene {
        WindowGroup {
            FileIntakeView()
        }
        .modelContainer(for: [RecentCoordinate.self, BatchRunSummary.self],
                        migrationPlan: AppMigrationPlan.self)
    }
}
