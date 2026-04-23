import SwiftUI

struct ProductDetailView: View {
    let product: Product
    @State private var seller: User?
    @State private var reviews: [Review] = []
    @State private var isFavorite = false
    @State private var showChat = false
    @State private var showMap = false
    @State private var showPayment = false
    
    private let firebaseManager = FirebaseManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Product Image
                AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 300)
                .clipped()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Title and Price
                    Text(product.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.title2)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                    
                    // Category
                    Text(product.category)
                        .padding(8)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    
                    // Description
                    Text("Description")
                        .font(.headline)
                    Text(product.description)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Seller Info
                    if let seller = seller {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seller Information")
                                .font(.headline)
                            
                            HStack {
                                AsyncImage(url: URL(string: seller.profileImageURL ?? "")) { image in
                                    image.resizable()
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(seller.name)
                                        .fontWeight(.semibold)
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", seller.averageRating))
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                    } else {
                        ProgressView()
                            .padding()
                    }
                    
                    Divider()
                    
                    // Reviews
                    Text("Reviews")
                        .font(.headline)
                    
                    if reviews.isEmpty {
                        Text("No reviews yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(reviews.prefix(3)) { review in
                            ReviewRowView(review: review)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            showChat = true
                        }) {
                            Label("Contact Seller", systemImage: "message.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        HStack {
                            Button(action: {
                                Task {
                                    await toggleFavorite()
                                }
                            }) {
                                Label(isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                      systemImage: isFavorite ? "heart.fill" : "heart")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFavorite ? Color.red : Color.gray.opacity(0.2))
                                    .foregroundColor(isFavorite ? .white : .primary)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                showMap = true
                            }) {
                                Label("View on Map", systemImage: "map.fill")
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
                            Label("Buy Now", systemImage: "cart.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
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
}

struct ReviewRowView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}