import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var seller: User?
    @State private var reviews: [Review] = []
    @State private var isFavorite = false
    @State private var showChat = false
    @State private var showMap = false
    @State private var showPayment = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
    private let firebaseManager = FirebaseManager.shared
    
    
    
    private var isOwnProduct: Bool {
    guard let currentUserID = firebaseManager.currentUser?.id else { return false }
    return currentUserID == product.sellerID
}

var body: some View {
    GeometryReader { geometry in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .frame(height: geometry.size.height * 0.35)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(product.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("BD \(product.price, specifier: "%.2f")")
                        .font(.title2)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 8) {
                        Text(product.category)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text(String(format: "%.1f", product.averageRating))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "shippingbox.fill")
                                .font(.caption)
                                .foregroundColor(product.quantity == 0 ? .red : .gray)
                            Text(product.quantity == 0 ? "Out of Stock" : "\(product.quantity) in stock")
                                .font(.subheadline)
                                .foregroundColor(product.quantity == 0 ? .red : .secondary)
                        }
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Divider()
                    
                    if let seller = seller {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seller Information")
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                AsyncImage(url: URL(string: seller.profileImageURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .overlay(
                                            Text(String(seller.name.prefix(1)))
                                                .font(.title3)
                                                .foregroundColor(.blue)
                                        )
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(seller.name)
                                        .font(.body)
                                        .fontWeight(.semibold)
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        Text(String(format: "%.1f", seller.averageRating))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        
                        Divider()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reviews")
                            .font(.headline)
                        
                        if reviews.isEmpty {
                            Text("No reviews yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding(.vertical, 4)
                        } else {
                            ForEach(reviews.prefix(3)) { review in
                                ReviewRowView(review: review)
                            }
                        }
                    }
                    
                    if !isOwnProduct {
                        VStack(spacing: 12) {
                            Button(action: {
                                showChat = true
                            }) {
                                Label("Contact Seller", systemImage: "message.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await toggleFavorite()
                                    }
                                }) {
                                    Label(isFavorite ? "Unfavorite" : "Favorite", 
                                          systemImage: isFavorite ? "heart.fill" : "heart")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(isFavorite ? Color.red : Color.gray.opacity(0.2))
                                        .foregroundColor(isFavorite ? .white : .primary)
                                        .cornerRadius(10)
                                }
                                
                                Button(action: {
                                    showMap = true
                                }) {
                                    Label("Map", systemImage: "map.fill")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            
                            Button(action: {
                                showPayment = true
                            }) {
                                Label(product.quantity == 0 ? "Out of Stock" : "Buy Now", systemImage: "cart.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(product.quantity == 0 ? Color.gray : Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(product.quantity == 0)
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("This is your listing")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            
                            Button(action: {
                                showMap = true
                            }) {
                                Label("View on Map", systemImage: "map.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(role: .destructive, action: {
                                showDeleteConfirm = true
                            }) {
                                if isDeleting {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .padding()
                                } else {
                                    Label("Delete Listing", systemImage: "trash.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                            }
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(10)
                            .disabled(isDeleting)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
    }
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showChat) {
        if let seller = seller {
            ChatView(otherUserID: seller.id ?? "", otherUserName: seller.name)
        }
    }
    .sheet(isPresented: $showMap) {
        ProductMapView(product: product)
    }
    .sheet(isPresented: $showPayment) {
        if let seller = seller {
            PaymentView(product: product, seller: seller)
        }
    }
    .task {
        await loadData()
    }
    .confirmationDialog("Delete this listing?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
        Button("Delete", role: .destructive) {
            deleteProduct()
        }
        Button("Cancel", role: .cancel) { }
    } message: {
        Text("This action cannot be undone.")
    }
    .alert("Error", isPresented: $showDeleteError) {
        Button("OK") { }
    } message: {
        Text(deleteErrorMessage)
    }
}
    
    func loadData() async {
        do {
            seller = try await firebaseManager.fetchUser(userID: product.sellerID)
            reviews = try await firebaseManager.fetchReviewsForProduct(productID: product.id ?? "")
            isFavorite = try await firebaseManager.isFavorite(productID: product.id ?? "")
        } catch {
            print("Error loading data: \(error)")
        }
    }
    
    func toggleFavorite() async {
        do {
            if isFavorite {
                try await firebaseManager.removeFavorite(productID: product.id ?? "")
            } else {
                try await firebaseManager.addFavorite(productID: product.id ?? "")
            }
            isFavorite.toggle()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    func deleteProduct() {
        guard let productID = product.id else { return }
        isDeleting = true
        
        Task {
            do {
                try await firebaseManager.deleteProduct(productID: productID)
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    deleteErrorMessage = error.localizedDescription
                    showDeleteError = true
                }
            }
        }
    }
}

struct ReviewRowView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                ForEach(0..<5) { index in
                    Image(systemName: index < review.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
                Spacer()
                Text(review.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(review.comment)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}