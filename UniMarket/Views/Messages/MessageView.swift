import SwiftUI

struct MessageView: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatView(conversation: conversation)) {
                        ConversationRow(conversation: conversation)
                    }
                }
            }
            .navigationTitle("Messages")
            .refreshable {
                await viewModel.fetchConversations()
            }
        }
        .task {
            await viewModel.fetchConversations()
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(conversation.otherUserName)
                    .font(.headline)
                
                if conversation.unreadCount > 0 {
                    Text("\(conversation.unreadCount)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                Text(conversation.lastMessageTimestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(conversation.itemTitle)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text(conversation.lastMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MessageView()
        .environmentObject(AuthViewModel())
        .environmentObject(MessageViewModel())
} 