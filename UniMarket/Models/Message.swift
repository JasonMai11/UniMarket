import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    let senderId: String
    let senderName: String
    let receiverId: String
    let receiverName: String
    let content: String
    let timestamp: Date
    let itemId: String
    let itemTitle: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId
        case senderName
        case receiverId
        case receiverName
        case content
        case timestamp
        case itemId
        case itemTitle
    }
}

struct Conversation: Identifiable {
    let id: String
    let otherUserId: String
    let otherUserName: String
    let lastMessage: String
    let lastMessageTimestamp: Date
    let itemId: String
    let itemTitle: String
    let unreadCount: Int
} 