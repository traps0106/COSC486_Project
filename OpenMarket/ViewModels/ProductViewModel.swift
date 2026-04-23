import Foundation
import CoreLocation
import Combine
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var selectedCategory: String = ""
    @Published var minPrice: String = ""
    @Published var maxPrice: String = ""
    @Published var searchRadius: Double = 50.0 // km
    
    private let firebaseManager = FirebaseManager.shared
    var userLocation: CLLocation?
    
    let categories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Other"]
    
    func fetchProducts() async {
        await MainActor.run { isLoading = true }
        
        do {
            let min = Double(minPrice) ?? nil
            let max = Double(maxPrice) ?? nil
            let category = selectedCategory.isEmpty ? nil : selectedCategory
            
            let fetchedProducts = try await firebaseManager.fetchProducts(
                category: category,
                minPrice: min,
                maxPrice: max,
                userLocation: userLocation,
                radius: searchRadius
            )
            
            await MainActor.run {
                products = fetchedProducts
                filteredProducts = fetchedProducts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func searchProducts(query: String) {
        if query.isEmpty {
            filteredProducts = products
        } else {
            filteredProducts = products.filter { product in
                product.title.localizedCaseInsensitiveContains(query) ||
                product.description.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func isNearby(product: Product) -> Bool {
        guard let userLocation = userLocation else { return false }
        return product.distance(from: userLocation) <= 10.0 // Within 10km
    }
}
