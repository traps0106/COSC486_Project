import SwiftUI
import CoreLocation

struct ProductListView: View {
    @StateObject private var viewModel = ProductViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var showFilters = false
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
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
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Button("Retry") {
                            Task {
                                await viewModel.fetchProducts()
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(viewModel.filteredProducts) { product in
                                NavigationLink(destination: ProductDetailView(product: product)) {
                                    ProductCardView(product: product, isNearby: viewModel.isNearby(product: product))
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("OpenMarket")
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
    
    var body: some View {
        VStack(alignment: .leading) {
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
            .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                HStack {
                    Text(product.category)
                        .font(.caption)
                        .padding(4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                    
                    if isNearby {
                        Text("Nearby")
                            .font(.caption)
                            .padding(4)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(5)
                    }
                }
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(String(format: "%.1f", product.averageRating))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}