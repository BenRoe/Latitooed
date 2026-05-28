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
    private var resolverMap: [UUID: CoordinateResolver] = [:]

    init(searchService: any CoordinateSearchServicing = MapKitCoordinateSearchService()) {
        self.searchService = searchService
    }

    deinit {
        // Tasks are Sendable; cancel is safe from any context. ObservationIgnored
        // properties are not Observation-tracked, so no isolation hop is required
        // even though this class is @MainActor.
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
        isSearchResultsExpanded = false // optimistic dismiss

        // Pick the resolver: prefer the service-provided one (works for MapKit
        // and test fakes uniformly — no concrete-type casts), fall back to a
        // pre-resolved coordinate on the result itself. Drop the selection if
        // neither is available rather than silently substituting a default (CR-01).
        let resolver: CoordinateResolver
        if let stored = resolverMap[result.id] {
            resolver = stored
        } else if let coord = result.coordinate {
            resolver = .immediate(coord)
        } else {
            return
        }

        // Cancel any prior in-flight resolve and clear any stale error-clear timer
        // so a 3-second-old failure can't wipe the next override (WR-04).
        activeResolveTask?.cancel()
        activeErrorClearTask?.cancel()
        activeErrorClearTask = nil

        // Fast path: an immediate resolver carries the coordinate inline, so set
        // synchronously. This preserves the contract that direct, pre-resolved
        // selections (recent picks, manual entries, test fakes) update the model
        // before selectSearchResult returns.
        if case .immediate(let coord) = resolver {
            setCoordinate(coord, label: result.title, collapseResults: false)
            readyStatusOverride = nil
            return
        }

        readyStatusOverride = "Resolving location…"
        activeResolveTask = Task { @MainActor [weak self, searchService] in
            guard let self else { return }
            do {
                let coord = try await searchService.resolve(resolver)
                guard !Task.isCancelled else { return }
                self.setCoordinate(coord, label: result.title, collapseResults: false)
                self.activeErrorClearTask?.cancel()
                self.activeErrorClearTask = nil
                self.readyStatusOverride = nil
            } catch is CancellationError {
                // Superseded by a newer selection or new search — drop silently.
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
        // Clear before each new search: stale resolvers belong to a prior query and
        // would let an obsolete tap resolve to the wrong place.
        resolverMap = [:]
        activeSearchTask?.cancel()
        // Cancel any in-flight resolve from the previous query — otherwise a late
        // resolve from the old search can overwrite a selection from the new one.
        activeResolveTask?.cancel()
        activeResolveTask = nil
        // Cancel the stale error-clear timer so it can't wipe the next override.
        activeErrorClearTask?.cancel()
        activeErrorClearTask = nil
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
                let bundle = try await searchService.search(for: query, near: searchCenter)
                guard let self, generation == self.searchGeneration, Task.isCancelled == false else {
                    return
                }

                self.resolverMap = bundle.resolvers
                self.searchResults = bundle.results
                self.searchStatus = bundle.results.isEmpty ? .noResults : .idle
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

    func cancelSearch() {
        activeSearchTask?.cancel()
        activeSearchTask = nil
        searchGeneration += 1
    }

    func clearSearch() {
        // Cancel any in-flight resolve and any stale error-clear timer so they
        // can't fire after the user has explicitly cleared the panel.
        activeResolveTask?.cancel()
        activeResolveTask = nil
        activeErrorClearTask?.cancel()
        activeErrorClearTask = nil
        readyStatusOverride = nil // clear any resolve error from prior selection attempt
        searchResults = []
        searchStatus = .idle
    }

    private func showResolveError() {
        activeErrorClearTask?.cancel() // cancel prior timer before starting new one
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

        if coordinate.displayText == selectedCoordinate?.displayText { return }
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
