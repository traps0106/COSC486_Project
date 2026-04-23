import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: ProductViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("All").tag("")
                        ForEach(viewModel.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Price Range") {
                    TextField("Min Price", text: $viewModel.minPrice)
                        .keyboardType(.decimalPad)
                    TextField("Max Price", text: $viewModel.maxPrice)
                        .keyboardType(.decimalPad)
                }
                
                Section("Location") {
                    VStack(alignment: .leading) {
                        Text("Search Radius: \(Int(viewModel.searchRadius)) km")
                        Slider(value: $viewModel.searchRadius, in: 5...100, step: 5)
                    }
                }
                
                Button("Apply Filters") {
                    Task {
                        await viewModel.fetchProducts()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}