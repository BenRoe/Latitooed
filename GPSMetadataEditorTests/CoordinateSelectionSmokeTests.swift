import MapKit
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

    @Test func mapCameraCenterClampsPoleLatitudeForVisibleSpan() throws {
        let northPole = try #require(CoordinateSelection(latitude: 90, longitude: 13.404954))
        let southPole = try #require(CoordinateSelection(latitude: -90, longitude: 13.404954))
        let span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)

        #expect(abs(CoordinateMapView.cameraCenter(for: northPole, span: span).latitude - 89.96) < 0.000001)
        #expect(abs(CoordinateMapView.cameraCenter(for: southPole, span: span).latitude + 89.96) < 0.000001)
    }
}
