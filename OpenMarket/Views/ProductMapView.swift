import SwiftUI
import MapKit

struct ProductMapView: View {
    let product: Product
    @Environment(\.dismiss) var dismiss
    @State private var cameraPosition: MapCameraPosition
    
    init(product: Product) {
        self.product = product
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: product.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                Marker(product.title, coordinate: product.coordinate)
            }
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: openInMaps) {
                        Label("Navigate", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                    }
                }
            }
        }
    }
    
    func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: product.coordinate))
        mapItem.name = product.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}