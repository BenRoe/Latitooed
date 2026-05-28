import Foundation
import MapKit

/// Opaque, service-owned token that names a single completion result so the
/// view-model can ask the service to resolve it later. Test fakes can construct
/// resolvers that already know a coordinate; the MapKit service constructs
/// resolvers backed by `MKLocalSearchCompletion` and resolves them with
/// `MKLocalSearch`.
nonisolated enum CoordinateResolver: Sendable {
    /// Pre-resolved coordinate (used by `FakeCoordinateSearchService`).
    case immediate(CoordinateSelection)
    /// MapKit completion that must be resolved via `MKLocalSearch`.
    case mapKitCompletion(MKLocalSearchCompletionBox)
}

/// Sendable wrapper around `MKLocalSearchCompletion` (an `NSObject` that is
/// safe to read across actors but not Sendable in Swift's strict model).
// @unchecked Sendable: immutable let wrapper — MKLocalSearchCompletion is safe to
// read across actors but not declared Sendable by MapKit.
nonisolated final class MKLocalSearchCompletionBox: @unchecked Sendable {
    let completion: MKLocalSearchCompletion
    init(_ completion: MKLocalSearchCompletion) { self.completion = completion }
}

/// Bundle returned by `CoordinateSearchServicing.search` so the view-model
/// never has to type-check the concrete service or read a mutable side-channel
/// property. The two arrays/dictionaries are produced atomically by the same
/// service callback, eliminating the index-misalignment race (see CR-03).
nonisolated struct CoordinateSearchResults: Sendable {
    let results: [CoordinateSearchResult]
    let resolvers: [UUID: CoordinateResolver]

    init(results: [CoordinateSearchResult], resolvers: [UUID: CoordinateResolver]) {
        self.results = results
        self.resolvers = resolvers
    }
}

protocol CoordinateSearchServicing: Sendable {
    func search(for query: String, near center: CoordinateSelection) async throws -> CoordinateSearchResults
    func resolve(_ resolver: CoordinateResolver) async throws -> CoordinateSelection
}

enum CoordinateSearchError: Error, Equatable, Sendable {
    case emptyQuery
    case unresolvable
}

@MainActor
private final class SearchCompleterDelegate: NSObject, @preconcurrency MKLocalSearchCompleterDelegate {
    /// UX cap from phase 08 plan — keep dropdown short enough to scan at a glance.
    static let maxCompletionsShown = 8

    private let completer: MKLocalSearchCompleter
    private var continuation: CheckedContinuation<CoordinateSearchResults, Error>?
    /// Identity stamp incremented per `search(for:)` call. The cancellation handler
    /// hops to MainActor asynchronously — by the time it runs, a fresh search may
    /// have already started. Snapshotting the ID at dispatch time and re-checking
    /// it on the MainActor lets us no-op when the cancel applies to a search that
    /// has already been superseded.
    private var currentSearchID: UInt64 = 0

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        // No region biasing: surface global results so users in any locale can find places.
        // Default resultTypes (.address | .pointOfInterest | .query) is appropriate.
    }

    func search(for query: String) async throws -> CoordinateSearchResults {
        if completer.isSearching { completer.cancel() }
        // CheckedContinuation requires exactly one resume. If a prior search is still
        // pending, hand it a CancellationError before dropping the reference so the
        // awaiting Task doesn't leak (SWIFT TASK CONTINUATION MISUSE).
        if let pending = continuation {
            pending.resume(throwing: CancellationError())
        }
        continuation = nil
        currentSearchID &+= 1
        let searchID = currentSearchID

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                self.continuation = cont
                // MKLocalSearchCompleter won't re-fire if queryFragment is unchanged.
                // Force a reset so the same query after a clear triggers a new event.
                if self.completer.queryFragment == query {
                    self.completer.queryFragment = ""
                }
                self.completer.queryFragment = query
            }
        } onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                // Identity guard: only cancel if we're still the in-flight search.
                // A freshly-started search past this point owns its own continuation
                // and completer state and must not be torn down by us.
                guard let self, self.currentSearchID == searchID else { return }
                self.continuation?.resume(throwing: CancellationError())
                self.continuation = nil
                self.completer.cancel()
            }
        }
    }

    // @preconcurrency conformance: MapKit calls these on the main thread via ObjC runtime.
    // The class is @MainActor so these run on MainActor — no nonisolated/assumeIsolated needed.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Ignore later updates: MKLocalSearchCompleter can fire this callback multiple
        // times per search as the query refines. Resuming twice traps; mutating
        // shared state after resume creates an alignment race. Snapshot once and bail.
        guard let cont = continuation else { return }
        continuation = nil

        let slice = Array(completer.results.prefix(Self.maxCompletionsShown))
        var resolvers: [UUID: CoordinateResolver] = [:]
        let results: [CoordinateSearchResult] = slice.map { completion in
            let result = CoordinateSearchResult(
                title: completion.title,
                subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
                coordinate: nil // resolved later via MKLocalSearch
            )
            resolvers[result.id] = .mapKitCompletion(MKLocalSearchCompletionBox(completion))
            return result
        }
        cont.resume(returning: CoordinateSearchResults(results: results, resolvers: resolvers))
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

@MainActor
final class MapKitCoordinateSearchService: CoordinateSearchServicing {
    private let delegate = SearchCompleterDelegate()

    func search(for query: String, near center: CoordinateSelection) async throws -> CoordinateSearchResults {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw CoordinateSearchError.emptyQuery
        }

        try Task.checkCancellation()
        let bundle = try await delegate.search(for: trimmedQuery)
        try Task.checkCancellation()
        return bundle
    }

    func resolve(_ resolver: CoordinateResolver) async throws -> CoordinateSelection {
        switch resolver {
        case .immediate(let coord):
            return coord
        case .mapKitCompletion(let box):
            let request = MKLocalSearch.Request(completion: box.completion)
            let response = try await MKLocalSearch(request: request).start()
            guard let item = response.mapItems.first,
                  let coord = CoordinateSelection(
                    latitude: item.location.coordinate.latitude,
                    longitude: item.location.coordinate.longitude
                  ) else {
                throw CoordinateSearchError.unresolvable
            }
            return coord
        }
    }
}
