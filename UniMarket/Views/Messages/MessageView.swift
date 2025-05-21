import SwiftUI

struct MessageView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var messageViewModel = MessageViewModel()
    @State private var selectedConversation: Conversation?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(messageViewModel.conversations) { conversation in
                    Button(action: {
                        selectedConversation = conversation
                    }) {
                        ConversationRow(conversation: conversation)
                    }
                }
            }
            .navigationTitle("Messages")
            .refreshable {
                if let userId = authViewModel.currentUser?.id {
                    await messageViewModel.fetchConversations(forUserId: userId)
                }
            }
            .sheet(item: $selectedConversation) { conversation in
                ChatView(conversation: conversation)
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    Task {
                        await messageViewModel.fetchConversations(forUserId: userId)
                    }
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.otherUserName)
                    .font(.headline)
                
                Text(conversation.itemTitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(conversation.lastMessageTimestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MessageView()
        .environmentObject(AuthViewModel())
} 