struct ReviewView: View {
    let product: Product
    let seller: User
    let onSubmit: () -> Void
    
    @State private var rating = 5
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    private let firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rate the Seller") {
                    HStack {
                        Spacer()
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.largeTitle)
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Your Review") {
                    TextField("Write your review...", text: $comment, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section {
                    Button(action: submitReview) {
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Submit Review")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSubmitting || comment.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    func submitReview() {
        guard !comment.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please write a review"
            showError = true
            return
        }
        
        guard let productID = product.id, let sellerID = seller.id else {
            errorMessage = "Missing product or seller information"
            showError = true
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                print("   Submitting review...")
                print("   Product ID: \(productID)")
                print("   Seller ID: \(sellerID)")
                print("   Rating: \(rating)")
                print("   Comment: \(comment)")
                
                try await firebaseManager.addReview(
                    productID: productID,
                    sellerID: sellerID,
                    rating: rating,
                    comment: comment
                )
                
                print("Review submitted successfully!")
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onSubmit()
                }
            } catch {
                print("Error submitting review: \(error)")
                print("   Error details: \(error.localizedDescription)")
                
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}