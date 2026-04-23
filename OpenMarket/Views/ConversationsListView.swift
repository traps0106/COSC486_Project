import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ConversationsListView: View {
    @State private var conversations: [Conversation] = []
    @State private var isLoading = false
    
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No messages yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Your conversations will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(conversations) { conversation in
                            NavigationLink(destination: ChatView(
                                otherUserID: conversation.otherUserID,
                                otherUserName: conversation.otherUserName
                            )) {
                                ConversationRow(conversation: conversation)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .task {
                await loadConversations()
            }
            .refreshable {
                await loadConversations()
            }
        }
    }
    
    func loadConversations() async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            // Fetch all messages where user is sender or receiver
            let snapshot = try await db.collection("messages")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            var conversationsDict: [String: Conversation] = [:]
            
            for document in snapshot.documents {
                guard let message = try? document.data(as: Message.self) else { continue }
                
                // Determine the other user
                let otherUserID: String
                if message.senderID == currentUserID {
                    otherUserID = message.receiverID
                } else if message.receiverID == currentUserID {
                    otherUserID = message.senderID
                } else {
                    continue // Not our conversation
                }
                
                // Only add if we haven't seen this conversation yet (most recent message wins)
                if conversationsDict[otherUserID] == nil {
                    // Fetch other user's name
                    if let otherUser = try? await FirebaseManager.shared.fetchUser(userID: otherUserID) {
                        conversationsDict[otherUserID] = Conversation(
                            id: otherUserID,
                            otherUserID: otherUserID,
                            otherUserName: otherUser.name,
                            lastMessage: message.text,
                            lastMessageTime: message.timestamp,
                            otherUserImageURL: otherUser.profileImageURL
                        )
                    }
                }
            }
            
            let conversationsList = Array(conversationsDict.values)
                .sorted { $0.lastMessageTime > $1.lastMessageTime }
            
            await MainActor.run {
                conversations = conversationsList
                isLoading = false
            }
        } catch {
            print("Error loading conversations: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

struct Conversation: Identifiable {
    let id: String
    let otherUserID: String
    let otherUserName: String
    let lastMessage: String
    let lastMessageTime: Date
    let otherUserImageURL: String?
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            AsyncImage(url: URL(string: conversation.otherUserImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Text(String(conversation.otherUserName.prefix(1)))
                            .font(.title3)
                            .foregroundColor(.blue)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.otherUserName)
                        .font(.headline)
                    Spacer()
                    Text(conversation.lastMessageTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}