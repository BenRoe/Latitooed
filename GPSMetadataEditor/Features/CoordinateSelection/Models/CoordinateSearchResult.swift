import Foundation

nonisolated struct CoordinateSearchResult: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String?
    let coordinate: CoordinateSelection

    init(id: UUID = UUID(), title: String, subtitle: String? = nil, coordinate: CoordinateSelection) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
