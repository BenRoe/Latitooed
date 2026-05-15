enum GPSStatus: String, CaseIterable, Sendable {
    case notChecked
    case notPresent
    case present
    case updated

    var displayName: String {
        switch self {
        case .notChecked:
            "Not checked"
        case .notPresent:
            "No GPS"
        case .present:
            "Has GPS"
        case .updated:
            "Updated"
        }
    }
}
