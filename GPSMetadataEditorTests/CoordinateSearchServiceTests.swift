import Testing
@testable import GPSMetadataEditor

struct CoordinateSearchServiceTests {
    @Test func fakeSearchServiceReturnsLightweightResult() async throws {
        let coordinate = try #require(CoordinateSelection(latitude: 52.520008, longitude: 13.404954))
        let result = CoordinateSearchResult(title: "Berlin", subtitle: "Germany", coordinate: coordinate)
        let service = FakeCoordinateSearchService(results: [result])

        let results = try await service.search(for: "Berlin", near: .berlin)

        #expect(results == [result])
    }

    @Test func emptyQueryErrorIsDistinct() {
        #expect(CoordinateSearchError.emptyQuery == .emptyQuery)
    }

    @Test func cancellationIsDistinguishableFromUserFacingFailure() async {
        let service = FakeCoordinateSearchService(error: CancellationError())

        await #expect(throws: CancellationError.self) {
            try await service.search(for: "Berlin", near: .berlin)
        }
    }
}
