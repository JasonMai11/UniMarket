import Foundation
import Firebase
import FirebaseFirestore

@MainActor
class MessageViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var unreadCount: Int = 0
    
    private let db = Firestore.firestore()
    
    func fetchConversations(forUserId userId: String) async {
        do {
            let snapshot = try await db.collection("messages")
                .whereFilter(Filter.orFilter([
                    Filter.whereField("senderId", isEqualTo: userId),
                    Filter.whereField("receiverId", isEqualTo: userId)
                ]))
                .order(by: "timestamp", descending: true)
                .getDocuments()
            
            // Group messages by conversation
            var conversationDict: [String: (Message, Int)] = [:]
            
            for document in snapshot.documents {
                if let message = try? document.data(as: Message.self) {
                    let otherUserId = message.senderId == userId ? message.receiverId : message.senderId
                    let otherUserName = message.senderId == userId ? message.receiverName : message.senderName
                    
                    let conversationId = "\(min(userId, otherUserId))_\(max(userId, otherUserId))_\(message.itemId)"
                    
                    if let existing = conversationDict[conversationId] {
                        if message.timestamp > existing.0.timestamp {
                            conversationDict[conversationId] = (message, existing.1 + (message.receiverId == userId ? 1 : 0))
                        } else {
                            conversationDict[conversationId] = (existing.0, existing.1 + (message.receiverId == userId ? 1 : 0))
                        }
                    } else {
                        conversationDict[conversationId] = (message, message.receiverId == userId ? 1 : 0)
                    }
                }
            }
            
            // Convert to conversations array
            self.conversations = conversationDict.map { (id, data) in
                let (message, unread) = data
                let otherUserId = message.senderId == userId ? message.receiverId : message.senderId
                let otherUserName = message.senderId == userId ? message.receiverName : message.senderName
                
                return Conversation(
                    id: id,
                    otherUserId: otherUserId,
                    otherUserName: otherUserName,
                    lastMessage: message.content,
                    lastMessageTimestamp: message.timestamp,
                    itemId: message.itemId,
                    itemTitle: message.itemTitle,
                    unreadCount: unread
                )
            }.sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
            
            // Calculate total unread count
            self.unreadCount = self.conversations.reduce(0) { $0 + $1.unreadCount }
            
        } catch {
            print("DEBUG: Failed to fetch conversations with error \(error.localizedDescription)")
        }
    }
    
    func fetchMessages(forItemId itemId: String, between userId1: String, and userId2: String) async {
        do {
            let snapshot = try await db.collection("messages")
                .whereFilter(Filter.andFilter([
                    Filter.whereField("itemId", isEqualTo: itemId),
                    Filter.orFilter([
                        Filter.andFilter([
                            Filter.whereField("senderId", isEqualTo: userId1),
                            Filter.whereField("receiverId", isEqualTo: userId2)
                        ]),
                        Filter.andFilter([
                            Filter.whereField("senderId", isEqualTo: userId2),
                            Filter.whereField("receiverId", isEqualTo: userId1)
                        ])
                    ])
                ]))
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            self.messages = snapshot.documents.compactMap { try? $0.data(as: Message.self) }
            
        } catch {
            print("DEBUG: Failed to fetch messages with error \(error.localizedDescription)")
        }
    }
    
    func sendMessage(_ message: Message) async throws {
        do {
            let encodedMessage = try Firestore.Encoder().encode(message)
            try await db.collection("messages").addDocument(data: encodedMessage)
            await fetchMessages(forItemId: message.itemId, between: message.senderId, and: message.receiverId)
        } catch {
            print("DEBUG: Failed to send message with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func markConversationAsRead(conversationId: String) async {
        // Implement marking messages as read
        // This would typically update a 'read' field in the messages
    }
} 