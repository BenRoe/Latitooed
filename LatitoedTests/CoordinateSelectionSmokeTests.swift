import MapKit
import Testing
@testable import Latitooed

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

        #expect(CoordinateMapView.cameraCenter(for: northPole, span: span).latitude == 85)
        #expect(CoordinateMapView.cameraCenter(for: southPole, span: span).latitude == -85)
    }

    @Test func mapMarkerCoordinateClampsExactPoleForRendering() throws {
        let northPole = try #require(CoordinateSelection(latitude: 90, longitude: 13.404954))
        let southPole = try #require(CoordinateSelection(latitude: -90, longitude: 13.404954))

        #expect(CoordinateMapView.markerCoordinate(for: northPole).latitude == 85)
        #expect(CoordinateMapView.markerCoordinate(for: southPole).latitude == -85)
    }

    @Test func mapMarkerCoordinateLeavesVisibleLatitudeUnchanged() throws {
        let coordinate = try #require(CoordinateSelection(latitude: 85, longitude: 13.404954))

        #expect(CoordinateMapView.markerCoordinate(for: coordinate).latitude == 85)
    }
}
