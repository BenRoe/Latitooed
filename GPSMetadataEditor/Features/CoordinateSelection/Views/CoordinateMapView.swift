import MapKit
import SwiftUI

struct CoordinateMapView: View {
    @Bindable var viewModel: CoordinateSelectionViewModel
    @State private var position: MapCameraPosition

    init(viewModel: CoordinateSelectionViewModel) {
        self.viewModel = viewModel
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: viewModel.defaultMapCenter.latitude,
                longitude: viewModel.defaultMapCenter.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )))
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $position) {
                if let coordinate = viewModel.selectedCoordinate {
                    Marker(
                        "Target",
                        coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                    )
                }
            }
            .mapStyle(mapStyle)
            .overlay(alignment: .topTrailing) {
                MapStyleOverlay(selectedStyle: viewModel.selectedMapStyle) { style in
                    viewModel.changeMapStyle(style)
                }
                .padding(AppDesign.Spacing.sm)
            }
            .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
            .onTapGesture(coordinateSpace: .local) { point in
                guard let coordinate = proxy.convert(point, from: .local) else {
                    return
                }

                viewModel.setCoordinateFromMap(latitude: coordinate.latitude, longitude: coordinate.longitude)
            }
        }
        .onChange(of: viewModel.selectedCoordinate) { _, newCoordinate in
            guard let newCoordinate else {
                return
            }

            position = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: newCoordinate.latitude, longitude: newCoordinate.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            ))
        }
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
}
