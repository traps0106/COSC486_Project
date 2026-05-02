import SwiftUI
import PhotosUI

struct AddProductView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var quantity = 1
    @State private var selectedCategory = "Electronics"
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @StateObject private var locationManager = LocationManager()
    private let firebaseManager = FirebaseManager.shared
    
    let categories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Image") {
    if let image = selectedImage {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: geometry.size.width)
                .cornerRadius(10)
        }
        .frame(height: 200)
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
    Text("Enter price for ONE item, not total")
        .font(.caption)
        .foregroundColor(.secondary)
}
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                }
                
                Section("Location") {
                    if let location = locationManager.location {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                            Text("Location captured")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Getting location...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button(action: addProduct) {
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
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle("Sell an Item")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    clearForm()
                }
            } message: {
                Text("Your product has been listed!")
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
        selectedImage != nil && 
        locationManager.location != nil
    }
    
    func addProduct() {
        guard let priceValue = Double(price) else {
            errorMessage = "Invalid price"
            showError = true
            return
        }
        
        guard let location = locationManager.location else {
            errorMessage = "Location not available"
            showError = true
            return
        }
        
        guard let image = selectedImage else {
            errorMessage = "Please select an image"
            showError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let productID = try await firebaseManager.addProduct(
                    title: title,
                    description: description,
                    price: priceValue,
                    category: selectedCategory,
                    image: image,
                    location: location.coordinate,
                    quantity: quantity
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
        quantity = 1
        selectedImage = nil
        selectedCategory = "Electronics"
    }
}