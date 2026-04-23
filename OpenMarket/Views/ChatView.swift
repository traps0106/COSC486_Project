import SwiftUI
import FirebaseAuth

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    
    let otherUserName: String
    
    init(otherUserID: String, otherUserName: String) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(otherUserID: otherUserID))
        self.otherUserName = otherUserName
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No messages yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Say hi to \(otherUserName)!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    let currentUserID = Auth.auth().currentUser?.uid ?? ""
                                    MessageBubble(message: message, isCurrentUser: message.senderID == currentUserID)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) { oldValue, newValue in
                            if let lastMessage = viewModel.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack(spacing: 12) {
                    TextField("Message", text: $viewModel.messageText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...4)
                    
                    Button(action: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundColor(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                    }
                    .disabled(viewModel.messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle(otherUserName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser { Spacer(minLength: 60) }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isCurrentUser { Spacer(minLength: 60) }
        }
    }
}