nonisolated struct FileIntakeResult: Equatable, Sendable {
    let accepted: [SelectedMediaFile]
    let warnings: [IntakeWarning]

    init(accepted: [SelectedMediaFile] = [], warnings: [IntakeWarning] = []) {
        self.accepted = accepted
        self.warnings = warnings
    }
}
