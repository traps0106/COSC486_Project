import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var messageText = ""
    
    private let firebaseManager = FirebaseManager.shared
    private var listener: ListenerRegistration?
    
    let otherUserID: String
    
    init(otherUserID: String) {
        self.otherUserID = otherUserID
        listenToMessages()
    }
    
    func listenToMessages() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        listener = firebaseManager.listenToMessages(userID: currentUserID, otherUserID: otherUserID) { [weak self] messages in
            DispatchQueue.main.async {
                self?.messages = messages
            }
        }
    }
    
    func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        do {
            try await firebaseManager.sendMessage(receiverID: otherUserID, text: messageText)
            await MainActor.run {
                messageText = ""
            }
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    deinit {
        listener?.remove()
    }
}
