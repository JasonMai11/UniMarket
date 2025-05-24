import SwiftUI

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
    ConversationRow(conversation: Conversation(
        id: "test",
        otherUserId: "test",
        otherUserName: "Test User",
        lastMessage: "Hello!",
        lastMessageTimestamp: Date(),
        itemId: "test",
        itemTitle: "Test Item",
        unreadCount: 2
    ))
} 