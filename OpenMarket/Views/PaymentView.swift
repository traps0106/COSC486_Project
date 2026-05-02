import SwiftUI

struct PaymentView: View {
    let product: Product
    let seller: User
    let quantityToBuy: Int
    @Environment(\.dismiss) private var dismiss
    @State private var showReview = false
    @State private var paymentComplete = false
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @ObservedObject private var settings = AppSettings.shared
    
    private let firebaseManager = FirebaseManager.shared
    
    private var totalPrice: Double {
        return product.price * Double(quantityToBuy)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if !paymentComplete {
                    ScrollView {
                        VStack(spacing: 24) {
                            Image(systemName: "creditcard.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                                .padding(.top, 40)
                            
                            Text("Order Summary")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            VStack(spacing: 16) {
                                AsyncImage(url: URL(string: product.imageURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                }
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Product")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(product.title)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Seller")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(seller.name)
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Price per item")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(settings.formatPrice(product.price))
                                            .fontWeight(.semibold)
                                    }
                                    
                                    HStack {
                                        Text("Quantity")
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(quantityToBuy)")
                                            .fontWeight(.semibold)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Total Amount")
                                            .font(.headline)
                                        Spacer()
                                        Text(settings.formatPrice(totalPrice))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                Text("⚠️ This is a mock payment")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("No real money will be charged")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            Button(action: completePurchase) {
                                HStack {
                                    if isPurchasing {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Complete Purchase")
                                    }
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isPurchasing ? Color.gray : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(isPurchasing)
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                    }
                } else {
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                        }
                        
                        Text("Purchase Complete!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Thank you for your order")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Order Details")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            HStack {
                                Text("\(quantityToBuy)x")
                                    .foregroundColor(.secondary)
                                Text(product.title)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Total Paid")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(settings.formatPrice(totalPrice))
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                showReview = true
                            }) {
                                HStack {
                                    Image(systemName: "star.fill")
                                    Text("Leave a Review")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button("Close") {
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !paymentComplete {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
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
    
    func completePurchase() {
        guard let productID = product.id else { return }
        
        isPurchasing = true
        
        Task {
            do {
                try await firebaseManager.purchaseProduct(productID: productID, quantityToBuy: quantityToBuy)
                
                await MainActor.run {
                    isPurchasing = false
                    withAnimation {
                        paymentComplete = true
                    }
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
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