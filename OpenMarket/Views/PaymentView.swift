import SwiftUI

struct PaymentView: View {
    let product: Product
    let seller: User
    @Environment(\.dismiss) var dismiss
    @State private var showReview = false
    @State private var paymentComplete = false
    
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
                        Text("Price: $\(product.price, specifier: "%.2f")")
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
    @Environment(\.dismiss) var dismiss
    
    private let firebaseManager = FirebaseManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Rate the Seller") {
                    HStack {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                rating = star
                            }) {
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                                    .font(.title)
                            }
                        }
                    }
                }
                
                Section("Your Review") {
                    TextField("Write your review...", text: $comment, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section {
                    Button(action: submitReview) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Review")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting || comment.isEmpty)
                }
            }
            .navigationTitle("Leave a Review")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    func submitReview() {
        isSubmitting = true
        Task {
            do {
                try await firebaseManager.addReview(
                    productID: product.id ?? "",
                    sellerID: seller.id ?? "",
                    rating: rating,
                    comment: comment
                )
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onSubmit()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                }
                print("Error submitting review: \(error)")
            }
        }
    }
}