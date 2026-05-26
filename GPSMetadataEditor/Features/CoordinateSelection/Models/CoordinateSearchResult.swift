import Foundation

nonisolated struct CoordinateSearchResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String?
    /// `nil` when the result is an unresolved MKLocalSearchCompletion that must be resolved
    /// via a follow-up MKLocalSearch. Non-nil when the producer already has the coordinate
    /// (e.g. test fakes or future direct-coordinate sources).
    let coordinate: CoordinateSelection?

    init(id: UUID = UUID(), title: String, subtitle: String? = nil, coordinate: CoordinateSelection? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
