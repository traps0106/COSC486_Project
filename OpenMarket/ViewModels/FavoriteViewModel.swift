import Foundation
import FirebaseAuth
import Combine

class FavoriteViewModel: ObservableObject {
    @Published var favorites: [Product] = []
    @Published var isLoading = false
    
    private let firebaseManager = FirebaseManager.shared
    
    func fetchFavorites() async {
        await MainActor.run { isLoading = true }
        
        do {
            let products = try await firebaseManager.fetchFavorites()
            await MainActor.run {
                favorites = products
                isLoading = false
            }
        } catch {
            print("Error fetching favorites: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func removeFavorite(productID: String) async {
        do {
            try await firebaseManager.removeFavorite(productID: productID)
            await fetchFavorites()
        } catch {
            print("Error removing favorite: \(error)")
        }
    }
}