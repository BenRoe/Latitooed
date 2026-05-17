import Foundation
import Observation

@Observable
@MainActor
final class CoordinateSelectionViewModel {
    enum SearchStatus: Equatable, Sendable {
        case idle
        case emptyQuery
        case searching
        case noResults
        case failed
    }

    var selectedCoordinate: CoordinateSelection?
    var latitudeField = CoordinateFieldState(kind: .latitude)
    var longitudeField = CoordinateFieldState(kind: .longitude)
    var selectedMapStyle: MapPresentationStyle = .standard
    var searchQuery = ""
    var isSearchResultsExpanded = false
    var searchStatus: SearchStatus = .idle
    var searchResults: [CoordinateSearchResult] = []

    @ObservationIgnored
    private let searchService: any CoordinateSearchServicing

    @ObservationIgnored
    private var activeSearchTask: Task<Void, Never>?

    @ObservationIgnored
    private var searchGeneration = 0

    init(searchService: any CoordinateSearchServicing = MapKitCoordinateSearchService()) {
        self.searchService = searchService
    }

    deinit {
        activeSearchTask?.cancel()
    }

    var defaultMapCenter: CoordinateSelection {
        Self.berlinCoordinate
    }

    var readyStatusText: String {
        guard let selectedCoordinate else {
            return "No target coordinate selected."
        }

        return "Target set: \(selectedCoordinate.displayText)"
    }

    var searchStatusText: String? {
        switch searchStatus {
        case .idle:
            nil
        case .emptyQuery:
            "Enter a place name to search."
        case .searching:
            "Searching..."
        case .noResults:
            "No places found. Try a different search."
        case .failed:
            "Places could not be loaded. Try again."
        }
    }

    var isSearchButtonDisabled: Bool {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func updateLatitude(_ text: String) {
        latitudeField.update(text, kind: .latitude)
        updateCoordinateFromFieldsIfValid()
    }

    func updateLongitude(_ text: String) {
        longitudeField.update(text, kind: .longitude)
        updateCoordinateFromFieldsIfValid()
    }

    func setCoordinateFromMap(latitude: Double, longitude: Double) {
        setCoordinate(latitude: latitude, longitude: longitude, collapseResults: true)
    }

    func selectSearchResult(_ result: CoordinateSearchResult) {
        setCoordinate(result.coordinate, collapseResults: true)
    }

    func collapseSearchResults() {
        isSearchResultsExpanded = false
    }

    func changeMapStyle(_ style: MapPresentationStyle) {
        selectedMapStyle = style
    }

    func search() {
        activeSearchTask?.cancel()
        searchGeneration += 1
        let generation = searchGeneration
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard query.isEmpty == false else {
            searchResults = []
            isSearchResultsExpanded = true
            searchStatus = .emptyQuery
            return
        }

        searchResults = []
        isSearchResultsExpanded = true
        searchStatus = .searching
        let searchCenter = selectedCoordinate ?? defaultMapCenter

        activeSearchTask = Task { [weak self, searchService] in
            do {
                let results = try await searchService.search(for: query, near: searchCenter)
                guard let self, generation == self.searchGeneration, Task.isCancelled == false else {
                    return
                }

                self.searchResults = results
                self.searchStatus = results.isEmpty ? .noResults : .idle
                self.activeSearchTask = nil
            } catch is CancellationError {
                guard let self, generation == self.searchGeneration else {
                    return
                }

                self.searchStatus = .idle
                self.activeSearchTask = nil
            } catch {
                guard let self, generation == self.searchGeneration else {
                    return
                }

                self.searchResults = []
                self.searchStatus = .failed
                self.activeSearchTask = nil
            }
        }
    }

    func performSearchOnSubmit() {
        search()
    }

    func cancelSearch() {
        activeSearchTask?.cancel()
        activeSearchTask = nil
        searchGeneration += 1
    }

    private func updateCoordinateFromFieldsIfValid() {
        guard let latitude = latitudeField.value,
              let longitude = longitudeField.value else {
            return
        }

        setCoordinate(latitude: latitude, longitude: longitude, collapseResults: true)
    }

    private func setCoordinate(latitude: Double, longitude: Double, collapseResults: Bool) {
        guard let coordinate = CoordinateSelection(latitude: latitude, longitude: longitude) else {
            return
        }

        setCoordinate(coordinate, collapseResults: collapseResults)
    }

    private func setCoordinate(_ coordinate: CoordinateSelection, collapseResults: Bool) {
        selectedCoordinate = coordinate
        latitudeField.sync(with: coordinate.latitude)
        longitudeField.sync(with: coordinate.longitude)

        if collapseResults {
            isSearchResultsExpanded = false
        }
    }

    private static let berlinCoordinate = CoordinateSelection.berlin
}
