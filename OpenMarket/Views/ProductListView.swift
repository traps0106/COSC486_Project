import SwiftUI
import CoreLocation

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var settings = AppSettings.shared
    @State private var searchText = ""
    @State private var showFilters = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    private var userName: String {
        FirebaseManager.shared.currentUser?.name ?? "Guest"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(userName)! 👋")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("What are you looking for today?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                
                HStack {
                    TextField("Search products...", text: $searchText)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onChange(of: searchText) { oldValue, newValue in
                            viewModel.searchProducts(query: newValue)
                        }
                    
                    Button(action: { showFilters.toggle() }) {
                        Image(systemName: "slider.horizontal.3")
                            .padding(10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            Task {
                                await viewModel.fetchProducts()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    Spacer()
                } else if viewModel.filteredProducts.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No products found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "Be the first to list something!" : "Try a different search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(viewModel.filteredProducts) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductCardView(product: product, isNearby: viewModel.isNearby(product: product))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Market")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showFilters) {
                FilterView(viewModel: viewModel)
            }
            .task {
                viewModel.userLocation = locationManager.location
                await viewModel.fetchProducts()
            }
        }
    }
}

struct ProductCardView: View {
    let product: Product
    let isNearby: Bool
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: geometry.size.width, height: geometry.size.width * 0.75)
                .clipped()
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(product.title)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .frame(height: 40, alignment: .top)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("\(settings.currency.symbol) \(product.price, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    HStack(spacing: 6) {
                        Text(product.category)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                        
                        if isNearby {
                            Text("Nearby")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
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
        .aspectRatio(0.75, contentMode: .fit)
    }
}