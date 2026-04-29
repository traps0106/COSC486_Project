import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var myProducts: [Product] = []
    @State private var isLoading = false
    
    private let firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let user = firebaseManager.currentUser {
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.blue.opacity(0.2))
                                    .overlay(
                                        Text(String(user.name.prefix(1)))
                                            .font(.title)
                                            .foregroundColor(.blue)
                                    )
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(user.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text(String(format: "%.1f", user.averageRating))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    } else if myProducts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("No listings yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Tap the + tab to create your first listing")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
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
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text("$\(product.price, specifier: "%.2f")")
                                            .font(.subheadline)
                                            .foregroundColor(.green)
                                            .fontWeight(.semibold)
                                        Text(product.category)
                                            .font(.caption)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                        Text(product.quantity == 0 ? "Out of Stock" : "\(product.quantity) in stock")
                                            .font(.caption)
                                            .foregroundColor(product.quantity == 0 ? .red : .secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete { indexSet in
                            Task {
                                await deleteProducts(at: indexSet)
                            }
                        }
                    }
                } header: {
                    Text("My Listings (\(myProducts.count))")
                }
                
                Section {
                    Button(role: .destructive, action: {
                        authViewModel.logout()
                    }) {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .fontWeight(.medium)
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
            return
        }
        
        await MainActor.run { isLoading = true }
        
        do {
            let products = try await firebaseManager.fetchProductsByUser(userID: userID)
            await MainActor.run {
                myProducts = products
                isLoading = false
            }
        } catch {
            print("Error loading products: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
    
    func deleteProducts(at indexSet: IndexSet) async {
        for index in indexSet {
            let product = myProducts[index]
            guard let productID = product.id else { continue }
            do {
                try await firebaseManager.deleteProduct(productID: productID)
                await MainActor.run {
                    myProducts.remove(at: index)
                }
            } catch {
                print("Error deleting product: \(error)")
            }
        }
    }
}