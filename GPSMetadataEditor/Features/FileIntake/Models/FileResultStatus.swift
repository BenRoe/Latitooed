nonisolated enum FileResultStatus: String, CaseIterable, Sendable {
    case pending
    case success
    case warning
    case failure

    var displayName: String {
        switch self {
        case .pending:
            "Pending"
        case .success:
            "Success"
        case .warning:
            "Warning"
        case .failure:
            "Failure"
        }
    }
}
