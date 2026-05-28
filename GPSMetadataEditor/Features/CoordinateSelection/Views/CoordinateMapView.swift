import MapKit
import SwiftUI

struct CoordinateMapView: View {
    @Bindable var viewModel: CoordinateSelectionViewModel
    @State private var position: MapCameraPosition

    init(viewModel: CoordinateSelectionViewModel) {
        self.viewModel = viewModel
        _position = State(initialValue: .region(Self.cameraRegion(for: viewModel.defaultMapCenter, span: Self.initialSpan)))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let coordinate = viewModel.selectedCoordinate {
                    Annotation("Target", coordinate: Self.markerCoordinate(for: coordinate), anchor: .bottom) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundStyle(.tint)
                            .background(.background, in: .circle)
                    }
                }
            }
            .mapStyle(mapStyle)
            .frame(
                minWidth: AppDesign.Layout.mapMinimumWidth,
                maxWidth: .infinity,
                minHeight: AppDesign.Layout.mapMinimumHeight,
                maxHeight: .infinity
            )
            .overlay(alignment: .topTrailing) {
                MapStyleOverlay(selectedStyle: viewModel.selectedMapStyle) { style in
                    viewModel.changeMapStyle(style)
                }
                .padding(AppDesign.Spacing.sm)
            }
            .clipShape(.rect(cornerRadius: AppDesign.Radius.medium))
            .simultaneousGesture(
                SpatialTapGesture()
                    .onEnded { value in
                        setCoordinate(at: value.location, using: proxy)
                    }
            )
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("Map. Tap to set GPS coordinate.")
            .accessibilityHint("Double-tap to place a coordinate pin at the tapped location.")
        }
        .onChange(of: viewModel.selectedCoordinate) { _, newCoordinate in
            guard let newCoordinate else {
                return
            }

            position = .region(Self.cameraRegion(for: newCoordinate, span: Self.selectionSpan))
        }
    }

    nonisolated static func cameraCenter(for coordinate: CoordinateSelection, span: MKCoordinateSpan) -> CLLocationCoordinate2D {
        let halfLatitudeDelta = min(abs(span.latitudeDelta) / 2, 90)
        let minimumLatitude = max(-90 + halfLatitudeDelta, -Self.maximumVisibleMapLatitude)
        let maximumLatitude = min(90 - halfLatitudeDelta, Self.maximumVisibleMapLatitude)
        let latitude = min(max(coordinate.latitude, minimumLatitude), maximumLatitude)

        return CLLocationCoordinate2D(latitude: latitude, longitude: coordinate.longitude)
    }

    nonisolated static func markerCoordinate(for coordinate: CoordinateSelection) -> CLLocationCoordinate2D {
        let latitude = min(max(coordinate.latitude, -Self.maximumVisibleMapLatitude), Self.maximumVisibleMapLatitude)

        return CLLocationCoordinate2D(latitude: latitude, longitude: coordinate.longitude)
    }

    private func setCoordinate(at point: CGPoint, using proxy: MapProxy) {
        guard let coordinate = proxy.convert(point, from: .local) else {
            return
        }

        viewModel.setCoordinateFromMap(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    private var mapStyle: MapStyle {
        switch viewModel.selectedMapStyle {
        case .standard:
            .standard
        case .satellite:
            .imagery
        case .hybrid:
            .hybrid
        }
    }

    nonisolated private static func cameraRegion(for coordinate: CoordinateSelection, span: MKCoordinateSpan) -> MKCoordinateRegion {
        MKCoordinateRegion(center: cameraCenter(for: coordinate, span: span), span: span)
    }

    nonisolated private static let initialSpan = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    nonisolated private static let selectionSpan = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    nonisolated private static let maximumVisibleMapLatitude = 85.0
}
