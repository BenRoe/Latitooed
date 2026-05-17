import Testing
@testable import GPSMetadataEditor

@MainActor
struct CoordinateSelectionSmokeTests {
    @Test func coordinateSelectionViewCanBeCreated() {
        let view = CoordinateSelectionView()

        #expect(String(describing: type(of: view)) == "CoordinateSelectionView")
    }

    @Test func integratedFileIntakeViewCanBeCreated() {
        let view = FileIntakeView()

        #expect(String(describing: type(of: view)) == "FileIntakeView")
    }
}
