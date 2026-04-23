import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import Combine
import UIKit
import CoreLocation

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published var currentUser: User?
    
    private init() {
        Task{
            await fetchCurrentUser()
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, name: String) async throws -> String {
        let result = try await auth.createUser(withEmail: email, password: password)
        let userID = result.user.uid
        
        let newUser = User(
            id: nil,  // Let Firestore handle the document ID
            name: name,
            email: email,
            profileImageURL: nil,
            averageRating: 0.0,
            createdAt: Date()
        )
        
        try db.collection("users").document(userID).setData(from: newUser)
        await fetchCurrentUser()
        return userID
    }
    
    func login(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
        await fetchCurrentUser()
    }
    
    func logout() throws {
        try auth.signOut()
        currentUser = nil
    }
    
    func fetchCurrentUser() async {
        guard let userID = auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(userID).getDocument()
            await MainActor.run {
                self.currentUser = try? snapshot.data(as: User.self)
            }
        } catch {
            print("Error fetching user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Products
    
    func addProduct(title: String, description: String, price: Double, category: String, image: UIImage?, location: CLLocationCoordinate2D) async throws -> String {
        print("FirebaseManager.addProduct() called")
        
        guard let userID = auth.currentUser?.uid else {
            print("Not authenticated - no current user")
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }
        print("User authenticated: \(userID)")
        
        var imageURL: String?
        if let image = image {
            print("Uploading image...")
            imageURL = try await uploadProductImage(image: image)
            print("Image uploaded: \(imageURL ?? "nil")")
        } else {
            print("No image to upload")
        }
        
        let product = Product(
            id: nil,
            title: title,
            description: description,
            price: price,
            category: category,
            imageURL: imageURL,
            sellerID: userID,
            latitude: location.latitude,
            longitude: location.longitude,
            averageRating: 0.0,
            createdAt: Date()
        )
        
        print("Saving product to Firestore...")
        let docRef = try db.collection("products").addDocument(from: product)
        print("Product saved with ID: \(docRef.documentID)")
        
        return docRef.documentID
    }
    
    func fetchProducts(category: String? = nil, minPrice: Double? = nil, maxPrice: Double? = nil, userLocation: CLLocation? = nil, radius: Double? = nil) async throws -> [Product] {
        var query: Query = db.collection("products")
        
        if let category = category, !category.isEmpty {
            query = query.whereField("category", isEqualTo: category)
        }
        
        let snapshot = try await query.getDocuments()
        var products = snapshot.documents.compactMap { try? $0.data(as: Product.self) }
        
        // Filter by price
        if let minPrice = minPrice {
            products = products.filter { $0.price >= minPrice }
        }
        if let maxPrice = maxPrice {
            products = products.filter { $0.price <= maxPrice }
        }
        
        // Filter by location radius
        if let userLocation = userLocation, let radius = radius {
            products = products.filter { product in
                product.distance(from: userLocation) <= radius
            }
        }
        
        return products
    }
    
    func fetchProductsByUser(userID: String) async throws -> [Product] {
        let snapshot = try await db.collection("products")
            .whereField("sellerID", isEqualTo: userID)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Product.self) }
    }
    
    func fetchProduct(productID: String) async throws -> Product? {
        let snapshot = try await db.collection("products").document(productID).getDocument()
        return try? snapshot.data(as: Product.self)
    }
    
    // MARK: - Favorites
    
    func addFavorite(productID: String) async throws {
        guard let userID = auth.currentUser?.uid else { return }
        
        let favorite = Favorite(
            id: nil,
            userID: userID,
            productID: productID,
            createdAt: Date()
        )
        
        try db.collection("favorites").addDocument(from: favorite)
    }
    
    func removeFavorite(productID: String) async throws {
        guard let userID = auth.currentUser?.uid else { return }
        
        let snapshot = try await db.collection("favorites")
            .whereField("userID", isEqualTo: userID)
            .whereField("productID", isEqualTo: productID)
            .getDocuments()
        
        for document in snapshot.documents {
            try await document.reference.delete()
        }
    }
    
    func fetchUserFavorites() async throws -> [Product] {
        guard let userID = auth.currentUser?.uid else { return [] }
        
        let snapshot = try await db.collection("favorites")
            .whereField("userID", isEqualTo: userID)
            .getDocuments()
        
        let favorites = snapshot.documents.compactMap { try? $0.data(as: Favorite.self) }
        var products: [Product] = []
        
        for favorite in favorites {
            if let product = try? await fetchProduct(productID: favorite.productID) {
                products.append(product)
            }
        }
        
        return products
    }
    
    func isFavorite(productID: String) async throws -> Bool {
        guard let userID = auth.currentUser?.uid else { return false }
        
        let snapshot = try await db.collection("favorites")
            .whereField("userID", isEqualTo: userID)
            .whereField("productID", isEqualTo: productID)
            .getDocuments()
        
        return !snapshot.documents.isEmpty
    }
    
    // MARK: - Reviews
    
    func addReview(productID: String, sellerID: String, rating: Int, comment: String) async throws {
        guard let userID = auth.currentUser?.uid else { return }
        
        let review = Review(
            id: nil,
            productID: productID,
            reviewerID: userID,
            sellerID: sellerID,
            rating: rating,
            comment: comment,
            timestamp: Date()
        )
        
        try db.collection("reviews").addDocument(from: review)
        
        // Update seller average rating
        try await updateSellerRating(sellerID: sellerID)
        try await updateProductRating(productID: productID)
    }
    
    func fetchReviewsForSeller(sellerID: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("sellerID", isEqualTo: sellerID)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }
    
    func fetchReviewsForProduct(productID: String) async throws -> [Review] {
        let snapshot = try await db.collection("reviews")
            .whereField("productID", isEqualTo: productID)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Review.self) }
    }
    
    private func updateSellerRating(sellerID: String) async throws {
        let reviews = try await fetchReviewsForSeller(sellerID: sellerID)
        guard !reviews.isEmpty else { return }
        
        let avgRating = Double(reviews.map { $0.rating }.reduce(0, +)) / Double(reviews.count)
        try await db.collection("users").document(sellerID).updateData(["averageRating": avgRating])
    }
    
    private func updateProductRating(productID: String) async throws {
        let reviews = try await fetchReviewsForProduct(productID: productID)
        guard !reviews.isEmpty else { return }
        
        let avgRating = Double(reviews.map { $0.rating }.reduce(0, +)) / Double(reviews.count)
        try await db.collection("products").document(productID).updateData(["averageRating": avgRating])
    }
    
    // MARK: - Messaging (Real-time)
    
    func sendMessage(receiverID: String, text: String) async throws {
        guard let senderID = auth.currentUser?.uid else { return }
        
        let message = Message(
            id: nil,
            senderID: senderID,
            receiverID: receiverID,
            text: text,
            timestamp: Date()
        )
        
        try db.collection("messages").addDocument(from: message)
    }
    
    func listenToMessages(userID: String, otherUserID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        // Combined listener for bidirectional messages
        return db.collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let allMessages = documents.compactMap { try? $0.data(as: Message.self) }
                
                // Filter messages between the two users
                let filteredMessages = allMessages.filter { message in
                    (message.senderID == userID && message.receiverID == otherUserID) ||
                    (message.senderID == otherUserID && message.receiverID == userID)
                }
                
                completion(filteredMessages)
            }
    }
    
    // MARK: - Storage
    
    func uploadProductImage(image: UIImage) async throws -> String {
        print("uploadProductImage() called - Using ImgBB")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("Failed to convert image to JPEG data")
            throw NSError(domain: "Image", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        print("Image converted to data: \(imageData.count) bytes")
        
        // ImgBB API endpoint
        let apiKey = "f7b4a8314fcd0e27d631e9e7d963bb10" // Replace with your key
        let uploadURL = URL(string: "https://api.imgbb.com/1/upload")!
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add API key
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"key\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(apiKey)\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("Uploading to ImgBB...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("ImgBB upload failed")
            throw NSError(domain: "Upload", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let dataDict = json["data"] as? [String: Any],
              let imageURL = dataDict["url"] as? String else {
            print("Failed to parse ImgBB response")
            throw NSError(domain: "Upload", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        print("Image uploaded to ImgBB: \(imageURL)")
        return imageURL
    }
    
    func uploadProfileImage(image: UIImage, userID: String) async throws -> String {
        print("uploadProfileImage() called - Using ImgBB")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("Failed to convert image to JPEG data")
            throw NSError(domain: "Image", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid image"])
        }
        
        // ImgBB API endpoint
        let apiKey = "f7b4a8314fcd0e27d631e9e7d963bb10" // Replace with your key
        let uploadURL = URL(string: "https://api.imgbb.com/1/upload")!
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add API key
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"key\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(apiKey)\r\n".data(using: .utf8)!)
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "Upload", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let dataDict = json["data"] as? [String: Any],
              let imageURL = dataDict["url"] as? String else {
            throw NSError(domain: "Upload", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        try await db.collection("users").document(userID).updateData(["profileImageURL": imageURL])
        
        return imageURL
    }
    
    func fetchUser(userID: String) async throws -> User? {
        let snapshot = try await db.collection("users").document(userID).getDocument()
        return try? snapshot.data(as: User.self)
    }
}
