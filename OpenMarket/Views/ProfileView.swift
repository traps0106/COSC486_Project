import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var myProducts: [Product] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let user = firebaseManager.currentUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(user.email)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(String(format: "%.1f", user.averageRating))
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                Section("My Listings (\(myProducts.count))") {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if myProducts.isEmpty {
                        Text("No listings yet")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(myProducts) { product in
                            NavigationLink(destination: ProductDetailView(product: product)) {
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product.title)
                                            .font(.headline)
                                            .lineLimit(2)
                                        Text("$\(product.price, specifier: "%.2f")")
                                            .foregroundColor(.green)
                                            .fontWeight(.semibold)
                                        Text(product.category)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        authViewModel.logout()
                    }) {
                        HStack {
                            Spacer()
                            Text("Logout")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .refreshable {
                await loadMyProducts()
            }
            .task {
                await loadMyProducts()
            }
        }
    }
    
    func loadMyProducts() async {
        guard let userID = Auth.auth().currentUser?.uid else {
            await MainActor.run { 
                errorMessage = "User not authenticated"
                isLoading = false
            }
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            let products = try await firebaseManager.fetchProductsByUser(userID: userID)
            await MainActor.run {
                myProducts = products
                isLoading = false
                errorMessage = nil
            }
        } catch {
            print("Error loading products: \(error)")
            await MainActor.run { 
                errorMessage = error.localizedDescription
                isLoading = false 
            }
        }
    }
}
