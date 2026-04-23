import SwiftUI
import PhotosUI
import Combine
struct AddProductView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var selectedCategory = "Electronics"
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isLoading = false
    @State private var showSuccess = false
    
    @StateObject private var locationManager = LocationManager()
    private let firebaseManager = FirebaseManager.shared
    
    let categories = ["Electronics", "Clothing", "Home", "Sports", "Books", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Image") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    Button("Select Image") {
                        showImagePicker = true
                    }
                }
                
                Section("Product Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                    }
                }
                
                Section("Location") {
                    if let location = locationManager.location {
                        Text("Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Getting location...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: addProduct) {
                        if isLoading {
                            ProgressView()
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
        }
    }
    
    var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty && !price.isEmpty && selectedImage != nil && locationManager.location != nil
    }
    
    func addProduct() {
        print("Add Product button pressed")
        print("Form validation check:")
        print("  - Title: '\(title)' (empty: \(title.isEmpty))")
        print("  - Description: '\(description)' (empty: \(description.isEmpty))")
        print("  - Price: '\(price)' (empty: \(price.isEmpty))")
        print("  - Image selected: \(selectedImage != nil)")
        print("  - Location available: \(locationManager.location != nil)")
        
        guard let priceValue = Double(price) else {
            print(" Invalid price: '\(price)' - cannot convert to number")
            return
        }
        print(" Price converted: \(priceValue)")
        
        guard let location = locationManager.location else {
            print(" No location available")
            return
        }
        print(" Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        if selectedImage == nil {
            print(" No image selected")
            return
        }
        print(" Image is selected")
        
        print(" Starting Firebase upload...")
        isLoading = true
        
        Task {
            do {
                print(" Calling firebaseManager.addProduct()...")
                let productID = try await firebaseManager.addProduct(
                    title: title,
                    description: description,
                    price: priceValue,
                    category: selectedCategory,
                    image: selectedImage,
                    location: location.coordinate
                )
                
                print(" SUCCESS! Product added with ID: \(productID)")
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    print(" Success alert should show now")
                }
            } catch {
                print(" ERROR adding product: \(error.localizedDescription)")
                print(" Full error: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    func clearForm() {
        title = ""
        description = ""
        price = ""
        selectedImage = nil
    }
}
