import Foundation

enum MapPresentationStyle: CaseIterable, Equatable, Sendable {
    case standard
    case satellite
    case hybrid

    var label: String {
        switch self {
        case .standard:
            "Standard"
        case .satellite:
            "Satellite"
        case .hybrid:
            "Hybrid"
        }
    }
}
