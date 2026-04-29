import SwiftUI

struct EditProductView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var price: String
    @State private var selectedCategory: String
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    private let firebaseManager = FirebaseManager.shared
    let categories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Other"]
    
    init(product: Product) {
        self.product = product
        _title = State(initialValue: product.title)
        _description = State(initialValue: product.description)
        _price = State(initialValue: String(format: "%.2f", product.price))
        _selectedCategory = State(initialValue: product.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Price (BD)", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section {
                    Button(action: saveChanges) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle("Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Product updated successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    var isFormValid: Bool {
        !title.isEmpty && 
        !description.isEmpty && 
        !price.isEmpty && 
        Double(price) != nil
    }
    
    func saveChanges() {
        guard let priceValue = Double(price) else {
            errorMessage = "Invalid price"
            showError = true
            return
        }
        
        guard let productID = product.id else {
            errorMessage = "Product ID not found"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                try await firebaseManager.updateProduct(
                    productID: productID,
                    title: title,
                    description: description,
                    price: priceValue,
                    category: selectedCategory
                )
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}