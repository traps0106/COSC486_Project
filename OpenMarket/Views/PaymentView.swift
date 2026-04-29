import SwiftUI

struct PaymentView: View {
    let product: Product
    let seller: User
    @Environment(\.dismiss) private var dismiss
    @State private var showReview = false
    @State private var paymentComplete = false
    @State private var quantityToBuy = 1
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let firebaseManager = FirebaseManager.shared

    var totalPrice: Double {
        product.price * Double(quantityToBuy)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if !paymentComplete {
                    Text("Mock Payment")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Product: \(product.title)")
                        Text("Price per item: $\(product.price, specifier: "%.2f")")
                        Text("Seller: \(seller.name)")
                        Text("Stock available: \(product.quantity)")
                            .foregroundColor(product.quantity == 0 ? .red : .secondary)

                        Divider()

                        Stepper("Quantity: \(quantityToBuy)", value: $quantityToBuy, in: 1...max(1, product.quantity))

                        HStack {
                            Text("Total:")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("$\(totalPrice, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()

                    if product.quantity == 0 {
                        Text("Out of Stock")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()

                    Button(action: completePurchase) {
                        if isProcessing {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Complete Purchase")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(product.quantity == 0 ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                    .disabled(product.quantity == 0 || isProcessing)

                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)

                        Text("Purchase Complete!")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("You bought \(quantityToBuy) x \(product.title)")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

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
            .alert("Purchase Failed", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func completePurchase() {
        guard let productID = product.id else { return }
        isProcessing = true

        Task {
            do {
                try await firebaseManager.purchaseProduct(productID: productID, quantityToBuy: quantityToBuy)
                await MainActor.run {
                    isProcessing = false
                    paymentComplete = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
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
