import SwiftUI
import CoreLocation

struct AddProductView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var quantity = "1"
    @State private var selectedCategory = "Electronics"
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var settings = AppSettings.shared
    private let firebaseManager = FirebaseManager.shared
    
    let categories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Other"]
    
    var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !price.isEmpty &&
        Double(price) != nil &&
        !quantity.isEmpty &&
        Int(quantity) != nil &&
        selectedImage != nil &&
        locationManager.location != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Image") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .cornerRadius(10)
                    }
                    
                    Button(action: { showImagePicker = true }) {
                        Label(selectedImage == nil ? "Select Image" : "Change Image",
                              systemImage: "photo")
                    }
                }
                
                Section("Product Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Price per item (BD)", text: $price)
                            .keyboardType(.decimalPad)
                        if settings.currency != .BHD {
                            HStack(spacing: 4) {
                                Text("≈ \(convertedPricePreview)")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            Text("Enter price in BD (base currency). Buyers will see it as \(settings.currency.symbol) \(convertedPricePreview)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Enter price for ONE item")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Quantity", text: $quantity)
                            .keyboardType(.numberPad)
                        Text("How many items do you have?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Location") {
                    HStack {
                        Image(systemName: locationManager.location != nil ? "checkmark.circle.fill" : "location.circle")
                            .foregroundColor(locationManager.location != nil ? .green : .gray)
                        Text(locationManager.location != nil ? "Location captured" : "Capturing location...")
                    }
                }
                
                Section {
                    Button(action: listProduct) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("List Product")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .navigationTitle("Sell an Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        clearForm()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ThemeToggleButton()
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    clearForm()
                }
            } message: {
                Text("Your product has been listed successfully!")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var convertedPricePreview: String {
        guard let priceValue = Double(price), priceValue > 0 else {
            return "0.00"
        }
        let converted = priceValue * settings.currency.exchangeRate
        return String(format: "%.2f", converted)
    }
    
    func listProduct() {
        guard let priceValue = Double(price),
              let quantityValue = Int(quantity),
              let location = locationManager.location else {
            return
        }
        
        isLoading = true
        
        Task {
            do {
                _ = try await firebaseManager.addProduct(
                    title: title,
                    description: description,
                    price: priceValue,
                    category: selectedCategory,
                    image: selectedImage,
                    location: location.coordinate,
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
    
    func clearForm() {
        title = ""
        description = ""
        price = ""
        quantity = "1"
        selectedCategory = "Electronics"
        selectedImage = nil
    }
}