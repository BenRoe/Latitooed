import Foundation
import Testing
@testable import GPSMetadataEditor

@MainActor
struct CoordinateSelectionViewModelTests {
    @Test func latitudeAcceptsBoundaryValues() throws {
        for value in [-90.0, 0.0, 90.0] {
            let coordinate = try #require(CoordinateSelection(latitude: value, longitude: 0))

            #expect(coordinate.latitude == value)
        }
    }

    @Test func longitudeAcceptsBoundaryValues() throws {
        for value in [-180.0, 0.0, 180.0] {
            let coordinate = try #require(CoordinateSelection(latitude: 0, longitude: value))

            #expect(coordinate.longitude == value)
        }
    }

    @Test func latitudeRejectsValuesOutsideRange() {
        #expect(CoordinateSelection(latitude: -90.1, longitude: 0) == nil)
        #expect(CoordinateSelection(latitude: 90.1, longitude: 0) == nil)
    }

    @Test func longitudeRejectsValuesOutsideRange() {
        #expect(CoordinateSelection(latitude: 0, longitude: -180.1) == nil)
        #expect(CoordinateSelection(latitude: 0, longitude: 180.1) == nil)
    }

    @Test func coordinateDisplayUsesSixFractionalDigits() throws {
        let coordinate = try #require(CoordinateSelection(latitude: 52.52, longitude: 13.4049542))

        #expect(coordinate.latitudeDisplay == "52.520000")
        #expect(coordinate.longitudeDisplay == "13.404954")
        #expect(coordinate.displayText == "52.520000, 13.404954")
    }

    @Test func newViewModelStartsWithoutSelectionAndUsesBerlinDefault() {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())

        #expect(viewModel.selectedCoordinate == nil)
        #expect(viewModel.defaultMapCenter.latitudeDisplay == "52.520008")
        #expect(viewModel.defaultMapCenter.longitudeDisplay == "13.404954")
    }

    @Test func validManualLatitudeAndLongitudeUpdatesSelectedCoordinate() throws {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())

        viewModel.updateLatitude("48.137154")
        viewModel.updateLongitude("11.576124")

        let coordinate = try #require(viewModel.selectedCoordinate)
        #expect(coordinate.latitude == 48.137154)
        #expect(coordinate.longitude == 11.576124)
    }

    @Test func invalidManualEditPreservesPreviousSelectionAndShowsValidation() throws {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())
        viewModel.updateLatitude("48.137154")
        viewModel.updateLongitude("11.576124")
        let original = try #require(viewModel.selectedCoordinate)

        viewModel.updateLatitude("91")

        #expect(viewModel.selectedCoordinate == original)
        #expect(viewModel.latitudeField.validationMessage == "Latitude must be between -90 and 90.")
    }

    @Test func manualFieldEditingDoesNotReformatTextWhileTyping() throws {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())
        viewModel.updateLatitude("48.137154")
        viewModel.updateLongitude("11.576124")

        viewModel.updateLatitude("48.13715")

        let coordinate = try #require(viewModel.selectedCoordinate)
        #expect(coordinate.latitude == 48.13715)
        #expect(viewModel.latitudeField.text == "48.13715")
    }

    @Test func clearingManualFieldKeepsEditableTextAndPreviousTarget() throws {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())
        viewModel.updateLatitude("48.137154")
        viewModel.updateLongitude("11.576124")
        let original = try #require(viewModel.selectedCoordinate)

        viewModel.updateLatitude("")

        #expect(viewModel.latitudeField.text == "")
        #expect(viewModel.latitudeField.validationMessage == nil)
        #expect(viewModel.selectedCoordinate == original)
    }

    @Test func validManualEditCollapsesSearchResults() {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())
        viewModel.isSearchResultsExpanded = true

        viewModel.updateLatitude("48.137154")
        viewModel.updateLongitude("11.576124")

        #expect(viewModel.isSearchResultsExpanded == false)
    }

    @Test func readyStatusReflectsSelectedCoordinate() {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())

        #expect(viewModel.readyStatusText == "No target coordinate selected.")

        viewModel.updateLatitude("52.520008")
        viewModel.updateLongitude("13.404954")

        #expect(viewModel.readyStatusText == "Target set: 52.520008, 13.404954")
    }

    @Test func explicitSearchPopulatesInlineResults() async throws {
        let coordinate = try #require(CoordinateSelection(latitude: 52.520008, longitude: 13.404954))
        let result = CoordinateSearchResult(title: "Berlin", subtitle: "Germany", coordinate: coordinate)
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService(results: [result]))
        viewModel.searchQuery = "Berlin"

        viewModel.search()
        await Task.yield()

        #expect(viewModel.searchResults == [result])
        #expect(viewModel.isSearchResultsExpanded == true)
        #expect(viewModel.searchStatusText == nil)
    }

    @Test func searchQueryMutationAloneDoesNotStartSearch() {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())

        viewModel.searchQuery = "Berlin"

        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.isSearchResultsExpanded == false)
        #expect(viewModel.searchStatusText == nil)
    }

    @Test func emptySearchShowsInlinePrompt() {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())

        viewModel.search()

        #expect(viewModel.isSearchResultsExpanded == true)
        #expect(viewModel.searchStatusText == "Enter a place name to search.")
    }

    @Test func selectingSearchResultSetsCoordinateAndCollapsesResults() throws {
        let coordinate = try #require(CoordinateSelection(latitude: 52.520008, longitude: 13.404954))
        let result = CoordinateSearchResult(title: "Berlin", coordinate: coordinate)
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())
        viewModel.searchQuery = "Berlin"
        viewModel.isSearchResultsExpanded = true

        viewModel.selectSearchResult(result)

        #expect(viewModel.selectedCoordinate == coordinate)
        #expect(viewModel.isSearchResultsExpanded == false)
        #expect(viewModel.searchQuery == "Berlin")
    }

    @Test func noResultSearchSetsQuietInlineStatus() async {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService(results: []))
        viewModel.searchQuery = "Atlantis"

        viewModel.search()
        await Task.yield()

        #expect(viewModel.searchStatusText == "No places found. Try a different search.")
    }

    @Test func failedSearchSetsQuietInlineStatus() async {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService(error: TestSearchError.failed))
        viewModel.searchQuery = "Berlin"

        viewModel.search()
        await Task.yield()

        #expect(viewModel.searchStatusText == "Places could not be loaded. Try again.")
    }

    @Test func canceledSearchDoesNotSetErrorStatus() async {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService(error: CancellationError()))
        viewModel.searchQuery = "Berlin"

        viewModel.search()
        await Task.yield()

        #expect(viewModel.searchStatusText == nil)
    }

    @Test func staleSearchResponseDoesNotOverwriteNewerState() async throws {
        let berlin = try #require(CoordinateSelection(latitude: 52.520008, longitude: 13.404954))
        let paris = try #require(CoordinateSelection(latitude: 48.856613, longitude: 2.352222))
        let service = DelayedCoordinateSearchService(resultsByQuery: [
            "Berlin": [CoordinateSearchResult(title: "Berlin", coordinate: berlin)],
            "Paris": [CoordinateSearchResult(title: "Paris", coordinate: paris)],
        ])
        let viewModel = CoordinateSelectionViewModel(searchService: service)

        viewModel.searchQuery = "Berlin"
        viewModel.search()
        viewModel.searchQuery = "Paris"
        viewModel.search()
        try await Task.sleep(for: .milliseconds(50))

        #expect(viewModel.searchResults.map(\.title) == ["Paris"])
    }

    @Test func mapCoordinateSelectionCollapsesResultsAndPreservesQuery() throws {
        let viewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())
        viewModel.searchQuery = "Berlin"
        viewModel.isSearchResultsExpanded = true

        viewModel.setCoordinateFromMap(latitude: 48.137154, longitude: 11.576124)

        let coordinate = try #require(viewModel.selectedCoordinate)
        #expect(coordinate.latitude == 48.137154)
        #expect(viewModel.isSearchResultsExpanded == false)
        #expect(viewModel.searchQuery == "Berlin")
    }
}

struct FakeCoordinateSearchService: CoordinateSearchServicing {
    var results: [CoordinateSearchResult] = []
    var error: (any Error & Sendable)?

    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult] {
        if let error {
            throw error
        }

        return results
    }
}

private enum TestSearchError: Error, Sendable {
    case failed
}

private struct DelayedCoordinateSearchService: CoordinateSearchServicing {
    let resultsByQuery: [String: [CoordinateSearchResult]]

    func search(for query: String, near center: CoordinateSelection) async throws -> [CoordinateSearchResult] {
        if query == "Berlin" {
            try await Task.sleep(for: .milliseconds(20))
        }

        return resultsByQuery[query, default: []]
    }
}
