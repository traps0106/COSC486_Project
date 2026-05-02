import SwiftUI

struct EditProductView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var price: String
    @State private var selectedCategory: String
    @State private var quantity: String
    
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
        _quantity = State(initialValue: String(product.quantity))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    VStack(alignment: .leading, spacing: 4) {
    TextField("Price per item (BD)", text: $price)
        .keyboardType(.decimalPad)
    Text("Price for ONE item")
        .font(.caption)
        .foregroundColor(.secondary)
}
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
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
        Double(price) != nil &&
        !quantity.isEmpty &&
        Int(quantity) != nil &&
        Int(quantity)! >= 0
    }
    
    func saveChanges() {
        guard let priceValue = Double(price) else {
            errorMessage = "Invalid price"
            showError = true
            return
        }
        
        guard let quantityValue = Int(quantity), quantityValue >= 0 else {
            errorMessage = "Invalid quantity (must be 0 or more)"
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
                    category: selectedCategory,
                    quantity: quantityValue
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