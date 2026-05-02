import Foundation
import CoreLocation
import Combine

class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var filteredProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    @Published var selectedCategory: String?
    @Published var minPrice: Double?
    @Published var maxPrice: Double?
    @Published var searchRadius: Double = 10.0
    
    var userLocation: CLLocation?
    
    private let firebaseManager = FirebaseManager.shared
    private let settings = AppSettings.shared
    
    func fetchProducts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedProducts = try await firebaseManager.fetchProducts()
            await MainActor.run {
                self.products = fetchedProducts
                self.filteredProducts = fetchedProducts
                self.isLoading = false
            }
            applyFilters()
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func searchProducts(query: String) {
        searchText = query
        applyFilters()
    }
    
    func applyFilters() {
        var results = products
        
        if !searchText.isEmpty {
            results = results.filter { product in
                product.title.localizedCaseInsensitiveContains(searchText) ||
                product.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let category = selectedCategory, !category.isEmpty {
            results = results.filter { $0.category == category }
        }
        
        if let minPrice = minPrice {
            let minPriceInBHD = minPrice / settings.currency.exchangeRate
            results = results.filter { $0.price >= minPriceInBHD }
        }
        
        if let maxPrice = maxPrice {
            let maxPriceInBHD = maxPrice / settings.currency.exchangeRate
            results = results.filter { $0.price <= maxPriceInBHD }
        }
        
        if let userLocation = userLocation {
            results = results.filter { product in
                product.distance(from: userLocation) <= searchRadius
            }
        }
        
        filteredProducts = results
    }
    
    func isNearby(product: Product) -> Bool {
        guard let userLocation = userLocation else { return false }
        return product.distance(from: userLocation) <= searchRadius
    }
}