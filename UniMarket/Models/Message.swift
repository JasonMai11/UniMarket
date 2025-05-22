import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable, Equatable {
    var id: String
    let conversationId: String
    let text: String?
    let imageUrl: String?
    let senderId: String
    let senderName: String
    let timestamp: Date
    var status: MessageStatus
    
    init(conversationId: String, text: String?, imageUrl: String?, senderId: String, senderName: String, timestamp: Date, status: MessageStatus = .sent) {
        self.id = UUID().uuidString
        self.conversationId = conversationId
        self.text = text
        self.imageUrl = imageUrl
        self.senderId = senderId
        self.senderName = senderName
        self.timestamp = timestamp
        self.status = status
    }
    
    enum MessageStatus: String, Codable {
        case sent
        case delivered
        case seen
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId
        case text
        case imageUrl
        case senderId
        case senderName
        case timestamp
        case status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        senderId = try container.decode(String.self, forKey: .senderId)
        senderName = try container.decode(String.self, forKey: .senderName)
        status = try container.decodeIfPresent(MessageStatus.self, forKey: .status) ?? .sent
        
        // Handle Firestore Timestamp
        if let timestamp = try container.decodeIfPresent(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else if let timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) {
            self.timestamp = timestamp
        } else {
            self.timestamp = Date()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(senderName, forKey: .senderName)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(status, forKey: .status)
    }
    
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.conversationId == rhs.conversationId &&
        lhs.text == rhs.text &&
        lhs.imageUrl == rhs.imageUrl &&
        lhs.senderId == rhs.senderId &&
        lhs.senderName == rhs.senderName &&
        lhs.timestamp == rhs.timestamp &&
        lhs.status == rhs.status
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