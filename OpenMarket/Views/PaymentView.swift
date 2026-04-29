import SwiftUI

struct PaymentView: View {
    let product: Product
    let seller: User
    @Environment(\.dismiss) private var dismiss
    @State private var showReview = false
    @State private var paymentComplete = false
    @StateObject private var settings = AppSettings.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if !paymentComplete {
                    Text("Mock Payment")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Product: \(product.title)")
                        Text("Price: \(settings.currency.symbol) \(product.price, specifier: "%.2f")")
                        Text("Seller: \(seller.name)")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        paymentComplete = true
                    }) {
                        Text("Complete Purchase")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Purchase Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Thank you for your purchase")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: {
                            showReview = true
                        }) {
                            Text("Leave a Review")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Button("Close") {
                            dismiss()
                        }
                        .padding(.bottom)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showReview) {
                ReviewView(product: product, seller: seller, onSubmit: {
                    dismiss()
                })
            }
        }
    }
}

struct ReviewView: View {
    let product: Product
    let seller: User
    let onSubmit: () -> Void
    
    @State private var rating = 5
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) private var dismiss
    
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
                    .disabled(isSubmitting || comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
    
    private func submitReview() {
        let trimmedComment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedComment.isEmpty else {
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
                try await firebaseManager.addReview(
                    productID: productID,
                    sellerID: sellerID,
                    rating: rating,
                    comment: trimmedComment
                )
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onSubmit()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}