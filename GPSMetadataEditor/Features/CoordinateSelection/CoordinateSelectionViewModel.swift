import Foundation
import MapKit
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
    var selectedCoordinateLabel: String?
    var latitudeField = CoordinateFieldState(kind: .latitude)
    var longitudeField = CoordinateFieldState(kind: .longitude)
    var selectedMapStyle: MapPresentationStyle = .standard
    var searchQuery = ""
    var isSearchResultsExpanded = false
    var searchStatus: SearchStatus = .idle
    var searchResults: [CoordinateSearchResult] = []

    // internal (not private) so @testable import tests can read/write directly
    var readyStatusOverride: String? = nil

    @ObservationIgnored
    private let searchService: any CoordinateSearchServicing

    @ObservationIgnored
    private var activeSearchTask: Task<Void, Never>?

    @ObservationIgnored
    private var activeResolveTask: Task<Void, Never>?

    @ObservationIgnored
    private var activeErrorClearTask: Task<Void, Never>?

    @ObservationIgnored
    private var searchGeneration = 0

    @ObservationIgnored
    private var completionMap: [UUID: MKLocalSearchCompletion] = [:]

    init(searchService: any CoordinateSearchServicing = MapKitCoordinateSearchService()) {
        self.searchService = searchService
    }

    deinit {
        activeSearchTask?.cancel()
        activeResolveTask?.cancel()
        activeErrorClearTask?.cancel()
    }

    var defaultMapCenter: CoordinateSelection {
        Self.berlinCoordinate
    }

    var readyStatusText: String {
        if let override = readyStatusOverride {
            return override
        }

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
        isSearchResultsExpanded = false // optimistic dismiss (D-01)

        guard let completion = completionMap[result.id] else {
            // No completion in map — FakeCoordinateSearchService path or old code path.
            // Fall back to direct coordinate set so all existing tests stay green.
            setCoordinate(result.coordinate, label: result.title, collapseResults: false)
            return
        }

        readyStatusOverride = "Resolving location…"
        activeResolveTask?.cancel()
        activeResolveTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let request = MKLocalSearch.Request(completion: completion)
                let response = try await MKLocalSearch(request: request).start()
                guard !Task.isCancelled else { return }
                if let item = response.mapItems.first,
                   let coord = CoordinateSelection(
                       latitude: item.placemark.coordinate.latitude,
                       longitude: item.placemark.coordinate.longitude
                   ) {
                    self.setCoordinate(coord, label: result.title, collapseResults: false)
                    self.readyStatusOverride = nil
                } else {
                    self.showResolveError()
                }
            } catch is CancellationError {
                // Superseded by a newer selection — drop silently
                return
            } catch {
                guard !Task.isCancelled else { return }
                self.showResolveError()
            }
        }
    }

    func selectRecentCoordinate(_ recentCoordinate: RecentCoordinateSnapshot) {
        setCoordinate(recentCoordinate.coordinate, label: recentCoordinate.label, collapseResults: true)
    }

    func selectBatchRunSummary(_ batchRunSummary: BatchRunSummarySnapshot) {
        setCoordinate(batchRunSummary.coordinate, label: batchRunSummary.coordinateLabel, collapseResults: true)
    }

    func selectLoadedFileCoordinate(_ coordinate: CoordinateSelection) {
        setCoordinate(coordinate, label: nil, collapseResults: true)
    }

    func collapseSearchResults() {
        isSearchResultsExpanded = false
    }

    func changeMapStyle(_ style: MapPresentationStyle) {
        selectedMapStyle = style
    }

    func search() {
        completionMap = [:] // Pitfall 5: clear stale entries before new search
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

        isSearchResultsExpanded = true
        searchStatus = .searching
        readyStatusOverride = nil // clear any prior resolve error when user starts new search
        let searchCenter = selectedCoordinate ?? defaultMapCenter

        activeSearchTask = Task { @MainActor [weak self, searchService] in
            do {
                let results = try await searchService.search(for: query, near: searchCenter)
                let genMatch = generation == (self?.searchGeneration ?? -1)
                print("[Search] got \(results.count) results, gen=\(generation), selfGen=\(self?.searchGeneration ?? -1), genMatch=\(genMatch), cancelled=\(Task.isCancelled)")
                guard let self, generation == self.searchGeneration, Task.isCancelled == false else {
                    print("[Search] guard failed — dropping results")
                    return
                }

                // Build completionMap from MapKitCoordinateSearchService.lastCompletions (Option B)
                // index-aligned with results via zip (Pitfall 4)
                if let concreteService = searchService as? MapKitCoordinateSearchService {
                    let completions = concreteService.lastCompletions
                    for (result, completion) in zip(results, completions) {
                        self.completionMap[result.id] = completion
                    }
                }
                // else: FakeCoordinateSearchService — completionMap stays empty, existing tests unaffected

                print("[Search] writing \(results.count) results to viewModel")
                self.searchResults = results
                self.searchStatus = results.isEmpty ? .noResults : .idle
                self.activeSearchTask = nil
                print("[Search] done, searchResults.count=\(self.searchResults.count)")
            } catch is CancellationError {
                print("[Search] CancellationError gen=\(generation)")
                guard let self, generation == self.searchGeneration else {
                    return
                }

                self.searchStatus = .idle
                self.activeSearchTask = nil
            } catch {
                print("[Search] error=\(error) gen=\(generation)")
                guard let self, generation == self.searchGeneration else {
                    return
                }

                self.searchResults = []
                self.searchStatus = .failed
                self.activeSearchTask = nil
            }
        }
    }

    func cancelSearch() {
        activeSearchTask?.cancel()
        activeSearchTask = nil
        searchGeneration += 1
    }

    func clearSearch() {
        readyStatusOverride = nil // clear any resolve error from prior selection attempt
        searchResults = []
        searchStatus = .idle
    }

    private func showResolveError() {
        activeErrorClearTask?.cancel() // cancel prior timer before starting new one (D-04)
        readyStatusOverride = "Could not load location. Try again."
        activeErrorClearTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(3))
            guard !(Task.isCancelled) else { return }
            self?.readyStatusOverride = nil
        }
    }

    private func updateCoordinateFromFieldsIfValid() {
        guard let latitude = latitudeField.value,
              let longitude = longitudeField.value else {
            return
        }

        guard let coordinate = CoordinateSelection(latitude: latitude, longitude: longitude) else {
            return
        }

        selectedCoordinate = coordinate
        selectedCoordinateLabel = nil
        isSearchResultsExpanded = false
    }

    private func setCoordinate(latitude: Double, longitude: Double, collapseResults: Bool) {
        guard let coordinate = CoordinateSelection(latitude: latitude, longitude: longitude) else {
            return
        }

        setCoordinate(coordinate, label: nil, collapseResults: collapseResults)
    }

    private func setCoordinate(_ coordinate: CoordinateSelection, label: String?, collapseResults: Bool) {
        selectedCoordinate = coordinate
        selectedCoordinateLabel = label
        latitudeField.sync(with: coordinate.latitude)
        longitudeField.sync(with: coordinate.longitude)

        if collapseResults {
            isSearchResultsExpanded = false
        }
    }

    private static let berlinCoordinate = CoordinateSelection.berlin
}
