import SwiftUI
import FirebaseAuth
import Combine

struct ConversationsListView: View {
    @StateObject private var viewModel = ConversationViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.conversations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No messages yet")
                            .font(.headline)
                        Text("Start chatting with sellers!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(
                            otherUserID: conversation.otherUserID,
                            otherUserName: conversation.otherUserName
                        )) {
                            ConversationRowView(conversation: conversation)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ThemeToggleButton()
                }
            }
            .task {
                await viewModel.loadConversations()
            }
            .refreshable {
                await viewModel.loadConversations()
            }
        }
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    
    var body: some View {
        HStack(spacing: 12) {
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
                Text(conversation.otherUserName)
                    .font(.headline)
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(conversation.lastMessageTime, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

class ConversationViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadConversations() async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        await MainActor.run { isLoading = true }
        
        do {
            let snapshot = try await firebaseManager.db.collection("messages")
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            var conversationsDict: [String: Conversation] = [:]
            
            for document in snapshot.documents {
                guard let message = try? document.data(as: Message.self) else { continue }
                
                let otherUserID: String
                if message.senderID == currentUserID {
                    otherUserID = message.receiverID
                } else if message.receiverID == currentUserID {
                    otherUserID = message.senderID
                } else {
                    continue
                }
                
                if conversationsDict[otherUserID] == nil {
                    let otherUser = try? await firebaseManager.fetchUser(userID: otherUserID)
                    conversationsDict[otherUserID] = Conversation(
                        id: otherUserID,
                        otherUserID: otherUserID,
                        otherUserName: otherUser?.name ?? "Unknown",
                        lastMessage: message.text,
                        lastMessageTime: message.timestamp,
                        otherUserImageURL: otherUser?.profileImageURL
                    )
                }
            }
            
            let sortedConversations = Array(conversationsDict.values)
                .sorted { $0.lastMessageTime > $1.lastMessageTime }
            
            await MainActor.run {
                conversations = sortedConversations
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