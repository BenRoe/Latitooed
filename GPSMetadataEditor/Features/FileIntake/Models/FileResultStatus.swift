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

    var systemImage: String {
        switch self {
        case .pending:
            "clock"
        case .success:
            "checkmark.circle"
        case .warning:
            "exclamationmark.triangle"
        case .failure:
            "xmark.circle"
        }
    }
}
