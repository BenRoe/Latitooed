import Foundation
import MapKit

nonisolated protocol CoordinateSearchServicing: Sendable {
    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult]
}

nonisolated enum CoordinateSearchError: Error, Equatable, Sendable {
    case emptyQuery
}

@MainActor
private final class SearchCompleterDelegate: NSObject, @preconcurrency MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    private(set) var lastCompletions: [MKLocalSearchCompletion] = []
    private var continuation: CheckedContinuation<[CoordinateSearchResult], Error>?

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        // D-02: no region — global search (A3: default resultTypes is fine)
    }

    func search(for query: String) async throws -> [CoordinateSearchResult] {
        if completer.isSearching { completer.cancel() }
        continuation = nil

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { cont in
                self.continuation = cont
                self.completer.queryFragment = query
            }
        } onCancel: { [weak self] in
            Task { @MainActor [weak self] in
                self?.continuation?.resume(throwing: CancellationError())
                self?.continuation = nil
                self?.completer.cancel()
            }
        }
    }

    // @preconcurrency conformance: MapKit calls these on the main thread via ObjC runtime.
    // The class is @MainActor so these run on MainActor — no nonisolated/assumeIsolated needed.
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let slice = Array(completer.results.prefix(8))
        lastCompletions = slice
        let results = slice.map { completion in
            CoordinateSearchResult(
                title: completion.title,
                subtitle: completion.subtitle.isEmpty ? nil : completion.subtitle,
                coordinate: .berlin
            )
        }
        continuation?.resume(returning: results)
        continuation = nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}

@MainActor
final class MapKitCoordinateSearchService: CoordinateSearchServicing {
    private let delegate = SearchCompleterDelegate()

    var lastCompletions: [MKLocalSearchCompletion] {
        delegate.lastCompletions
    }

    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw CoordinateSearchError.emptyQuery
        }

        try Task.checkCancellation()
        let results = try await delegate.search(for: trimmedQuery)
        try Task.checkCancellation()
        print("[Completer] '\(trimmedQuery)' → \(results.count) completions")
        return results
    }
}
