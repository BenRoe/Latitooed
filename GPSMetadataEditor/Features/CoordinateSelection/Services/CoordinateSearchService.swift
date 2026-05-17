import Foundation
import MapKit

protocol CoordinateSearchServicing: Sendable {
    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult]
}

struct MapKitCoordinateSearchService: CoordinateSearchServicing {
    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            throw CoordinateSearchError.emptyQuery
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        request.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        try Task.checkCancellation()
        let response = try await MKLocalSearch(request: request).start()
        try Task.checkCancellation()

        return response.mapItems.compactMap { item in
            guard let coordinate = CoordinateSelection(
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude
            ) else {
                return nil
            }

            return CoordinateSearchResult(
                title: item.name ?? item.placemark.title ?? trimmedQuery,
                subtitle: item.placemark.title,
                coordinate: coordinate
            )
        }
    }
}

enum CoordinateSearchError: Error, Equatable, Sendable {
    case emptyQuery
}
