import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoriteViewModel()
    @ObservedObject private var settings = AppSettings.shared
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No favorites yet")
                            .font(.headline)
                        Text("Start adding products you like!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.favorites) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    FavoriteCardView(product: product)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .contextMenu {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.removeFavorite(productID: product.id ?? "")
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favorites")
            .task {
                await viewModel.fetchFavorites()
            }
            .refreshable {
                await viewModel.fetchFavorites()
            }
        }
    }
}

struct FavoriteCardView: View {
    let product: Product
    @ObservedObject private var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(height: 150)
            .clipped()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                Text("\(settings.currency.symbol) \(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", product.averageRating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}