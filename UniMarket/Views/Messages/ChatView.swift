import SwiftUI

struct ChatView: View {
    let conversation: Conversation
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var messageViewModel = MessageViewModel()
    @State private var messageText = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messageViewModel.messages) { message in
                        MessageBubble(message: message, isFromCurrentUser: message.senderId == authViewModel.currentUser?.id)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button(action: {
                    sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .padding(.trailing)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .shadow(radius: 1)
        }
        .navigationTitle(conversation.otherUserName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            Task {
                await messageViewModel.fetchMessages(
                    forItemId: conversation.itemId,
                    between: authViewModel.currentUser?.id ?? "",
                    and: conversation.otherUserId
                )
            }
        }
    }
    
    private func sendMessage() {
        guard let currentUser = authViewModel.currentUser,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = Message(
            senderId: currentUser.id ?? "",
            senderName: currentUser.fullName,
            receiverId: conversation.otherUserId,
            receiverName: conversation.otherUserName,
            content: messageText.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: Date(),
            itemId: conversation.itemId,
            itemTitle: conversation.itemTitle
        )
        
        Task {
            do {
                try await messageViewModel.sendMessage(message)
                messageText = ""
            } catch {
                print("DEBUG: Failed to send message with error \(error.localizedDescription)")
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(isFromCurrentUser ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
    }
}

#Preview {
    NavigationView {
        ChatView(conversation: Conversation(
            id: "preview",
            otherUserId: "other",
            otherUserName: "John Doe",
            lastMessage: "Hello!",
            lastMessageTimestamp: Date(),
            itemId: "item1",
            itemTitle: "Sample Item",
            unreadCount: 0
        ))
        .environmentObject(AuthViewModel())
    }
} 