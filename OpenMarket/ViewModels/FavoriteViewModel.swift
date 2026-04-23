import Foundation
import Combine
class FavoriteViewModel: ObservableObject {
    @Published var favorites: [Product] = []
    @Published var isLoading = false
    
    private let firebaseManager = FirebaseManager.shared
    
    func fetchFavorites() async {
        await MainActor.run { isLoading = true }
        
        do {
            let fetchedFavorites = try await firebaseManager.fetchUserFavorites()
            await MainActor.run {
                favorites = fetchedFavorites
                isLoading = false
            }
        } catch {
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
