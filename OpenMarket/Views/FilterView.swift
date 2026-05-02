import SwiftUI

struct FilterView: View {
    @ObservedObject var viewModel: ProductViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var settings = AppSettings.shared
    
    @State private var selectedCategory: String = ""
    @State private var minPrice: String = ""
    @State private var maxPrice: String = ""
    @State private var searchRadius: Double = 10.0
    
    let categories = ["", "Electronics", "Clothing", "Home", "Sports", "Books", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag("")
                        ForEach(categories.filter { !$0.isEmpty }, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    HStack {
                        Text("Min (\(settings.currency.symbol))")
                        Spacer()
                        TextField("0", text: $minPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Max (\(settings.currency.symbol))")
                        Spacer()
                        TextField("No limit", text: $maxPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                } header: {
                    Text("Price Range")
                } footer: {
                    Text("Prices shown in \(settings.currency.name)")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Radius")
                            Spacer()
                            Text("\(Int(searchRadius)) km")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $searchRadius, in: 1...50, step: 1)
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Show products within this distance")
                }
                
                Section {
                    Button("Apply Filters") {
                        applyFilters()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .fontWeight(.semibold)
                    
                    Button("Clear All") {
                        clearFilters()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentFilters()
            }
        }
    }
    
    func loadCurrentFilters() {
        selectedCategory = viewModel.selectedCategory ?? ""
        
        if let min = viewModel.minPrice {
            minPrice = String(format: "%.2f", min)
        }
        if let max = viewModel.maxPrice {
            maxPrice = String(format: "%.2f", max)
        }
        
        searchRadius = viewModel.searchRadius
    }
    
    func applyFilters() {
        viewModel.selectedCategory = selectedCategory.isEmpty ? nil : selectedCategory
        
        if let minVal = Double(minPrice), minVal > 0 {
            viewModel.minPrice = minVal
        } else {
            viewModel.minPrice = nil
        }
        
        if let maxVal = Double(maxPrice), maxVal > 0 {
            viewModel.maxPrice = maxVal
        } else {
            viewModel.maxPrice = nil
        }
        
        viewModel.searchRadius = searchRadius
        viewModel.applyFilters()
    }
    
    func clearFilters() {
        selectedCategory = ""
        minPrice = ""
        maxPrice = ""
        searchRadius = 10.0
        
        viewModel.selectedCategory = nil
        viewModel.minPrice = nil
        viewModel.maxPrice = nil
        viewModel.searchRadius = 10.0
        viewModel.applyFilters()
    }
}