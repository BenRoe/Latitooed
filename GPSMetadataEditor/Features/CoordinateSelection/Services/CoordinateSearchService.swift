import Foundation
import MapKit

nonisolated protocol CoordinateSearchServicing: Sendable {
    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult]
}

nonisolated struct MapKitCoordinateSearchService: CoordinateSearchServicing {
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
            let mapCoordinate = item.location.coordinate
            let subtitle = item.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true)

            guard let coordinate = CoordinateSelection(
                latitude: mapCoordinate.latitude,
                longitude: mapCoordinate.longitude
            ) else {
                return nil
            }

            return CoordinateSearchResult(
                title: item.name ?? subtitle ?? trimmedQuery,
                subtitle: subtitle,
                coordinate: coordinate
            )
        }
    }
}

nonisolated enum CoordinateSearchError: Error, Equatable, Sendable {
    case emptyQuery
}
