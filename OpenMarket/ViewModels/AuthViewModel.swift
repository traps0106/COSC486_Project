import Foundation
import Combine
import FirebaseAuth

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let firebaseManager = FirebaseManager.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            // Check if user is already logged in via Firebase Auth
            let isLoggedIn = Auth.auth().currentUser != nil
            await firebaseManager.fetchCurrentUser()
            await MainActor.run {
                isAuthenticated = isLoggedIn && firebaseManager.currentUser != nil
            }
        }
    }
    
    func signUp(email: String, password: String, name: String) async {
        do {
            _ = try await firebaseManager.signUp(email: email, password: password, name: name)
            await MainActor.run {
                isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func login(email: String, password: String) async {
        do {
            try await firebaseManager.login(email: email, password: password)
            await MainActor.run {
                isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func logout() {
        do {
            try firebaseManager.logout()
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
