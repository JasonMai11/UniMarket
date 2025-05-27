import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth
import UserNotifications

@MainActor
class MessageViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [Message] = []
    @Published var unreadCount: Int = 0
    @Published var isOtherUserVerified = false
    @Published var isLoading = false
    
    private let db = Firestore.firestore()
    private var messageListener: ListenerRegistration?
    private var conversationListener: ListenerRegistration?
    private var listenerRegistration: ListenerRegistration?
    
    init() {
        setupSignOutObserver()
    }
    
    deinit {
        Task { @MainActor in
            messageListener?.remove()
            conversationListener?.remove()
            removeListener()
        }
    }
    
    private func setupSignOutObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignOut),
            name: .userDidSignOut,
            object: nil
        )
    }
    
    @objc private func handleSignOut() {
        // Clear all messages and conversations
        messages.removeAll()
        conversations.removeAll()
        
        // Remove any active listeners
        removeListener()
    }
    
    private func removeListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    func setupMessageNotifications() {
        // Remove existing listeners
        messageListener?.remove()
        conversationListener?.remove()
        
        // Listen for new conversations
        conversationListener = db.collection("conversations")
            .whereField("participants.\(Auth.auth().currentUser?.uid ?? "")", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("DEBUG: Failed to listen for conversations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                // Check for new messages in each conversation
                for document in documents {
                    if let unreadCount = document.data()["unreadCount"] as? Int,
                       unreadCount > 0 {
                        // Send local notification
                        self.sendLocalNotification(
                            title: document.data()["otherUserName"] as? String ?? "New Message",
                            body: document.data()["lastMessage"] as? String ?? "You have a new message"
                        )
                    }
                }
            }
    }
    
    private func sendLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("DEBUG: Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("DEBUG: Notification permission granted")
            } else if let error = error {
                print("DEBUG: Failed to request notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchConversations() async {
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("DEBUG: No current user found")
            return 
        }
        
        print("DEBUG: Fetching conversations for user: \(userId)")
        
        do {
            let snapshot = try await db.collection("conversations")
                .whereField("participants.\(userId)", isEqualTo: true)
                .order(by: "lastMessageTimestamp", descending: true)
                .getDocuments()
            
            print("DEBUG: Found \(snapshot.documents.count) conversations")
            
            DispatchQueue.main.async {
                self.conversations = snapshot.documents.compactMap { document in
                    let data = document.data()
                    print("DEBUG: Processing conversation document: \(document.documentID)")
                    print("DEBUG: Document data: \(data)")
                    
                    guard let participants = data["participants"] as? [String: Bool],
                          let otherUserId = participants.keys.first(where: { $0 != userId }),
                          let lastMessage = data["lastMessage"] as? String,
                          let lastMessageTimestamp = (data["lastMessageTimestamp"] as? Timestamp)?.dateValue(),
                          let itemId = data["itemId"] as? String,
                          let itemTitle = data["itemTitle"] as? String,
                          let unreadCount = data["unreadCount"] as? Int else {
                        print("DEBUG: Failed to parse conversation data")
                        return nil
                    }
                    
                    // Fetch the other user's name from Firestore
                    Task {
                        do {
                            let userDoc = try await self.db.collection("users").document(otherUserId).getDocument()
                            if let userName = userDoc.data()?["fullName"] as? String {
                                DispatchQueue.main.async {
                                    if let index = self.conversations.firstIndex(where: { $0.id == document.documentID }) {
                                        self.conversations[index] = Conversation(
                                            id: document.documentID,
                                            otherUserId: otherUserId,
                                            otherUserName: userName,
                                            lastMessage: lastMessage,
                                            lastMessageTimestamp: lastMessageTimestamp,
                                            itemId: itemId,
                                            itemTitle: itemTitle,
                                            unreadCount: unreadCount
                                        )
                                    }
                                }
                            }
                        } catch {
                            print("DEBUG: Failed to fetch user name: \(error.localizedDescription)")
                        }
                    }
                    
                    return Conversation(
                        id: document.documentID,
                        otherUserId: otherUserId,
                        otherUserName: data["otherUserName"] as? String ?? "Unknown",
                        lastMessage: lastMessage,
                        lastMessageTimestamp: lastMessageTimestamp,
                        itemId: itemId,
                        itemTitle: itemTitle,
                        unreadCount: unreadCount
                    )
                }
                print("DEBUG: Updated conversations array with \(self.conversations.count) conversations")
            }
        } catch {
            print("DEBUG: Failed to fetch conversations: \(error.localizedDescription)")
        }
    }
    
    func createConversation(with otherUserId: String, otherUserName: String, itemId: String, itemTitle: String) async throws -> String {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("DEBUG: No current user found when creating conversation")
            throw NSError(domain: "MessageViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        print("DEBUG: Creating conversation between \(currentUserId) and \(otherUserId) for item \(itemId)")
        
        // Create a unique conversation ID
        let conversationId = "\(min(currentUserId, otherUserId))_\(max(currentUserId, otherUserId))_\(itemId)"
        
        // Check if conversation already exists
        let existingConversation = try? await db.collection("conversations").document(conversationId).getDocument()
        if existingConversation?.exists == true {
            print("DEBUG: Conversation already exists: \(conversationId)")
            return conversationId
        }
        
        // Fetch the other user's name from Firestore
        let otherUserDoc = try await db.collection("users").document(otherUserId).getDocument()
        let otherUserName = otherUserDoc.data()?["fullName"] as? String ?? otherUserName
        
        // Create new conversation with participants as a dictionary
        let participants: [String: Bool] = [
            currentUserId: true,
            otherUserId: true
        ]
        
        let conversationData: [String: Any] = [
            "participants": participants,
            "otherUserName": otherUserName,
            "lastMessage": "",
            "lastMessageTimestamp": Timestamp(date: Date()),
            "itemId": itemId,
            "itemTitle": itemTitle,
            "unreadCount": 0
        ]
        
        print("DEBUG: Creating new conversation with data: \(conversationData)")
        
        try await db.collection("conversations").document(conversationId).setData(conversationData)
        print("DEBUG: Successfully created conversation: \(conversationId)")
        
        // Fetch conversations immediately after creating a new one
        await fetchConversations()
        
        return conversationId
    }
    
    func markConversationAsRead(_ conversationId: String) async {
        do {
            try await db.collection("conversations").document(conversationId).updateData([
                "unreadCount": 0
            ])
        } catch {
            print("DEBUG: Failed to mark conversation as read: \(error.localizedDescription)")
        }
    }
    
    func fetchMessages(forConversationId conversationId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Remove existing listener if any
        messageListener?.remove()
        
        do {
            // Set up real-time listener for messages
            messageListener = db.collection("messages")
                .whereField("conversationId", isEqualTo: conversationId)
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("DEBUG: Failed to fetch messages with error \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("DEBUG: No messages found")
                        return
                    }
                    
                    self.messages = documents.compactMap { try? $0.data(as: Message.self) }
                    
                    // Mark messages as seen if they're from the other user
                    Task {
                        await self.markUnreadMessagesAsSeen()
                    }
                }
        } catch {
            print("DEBUG: Failed to set up message listener: \(error.localizedDescription)")
        }
    }
    
    private func markUnreadMessagesAsSeen() async {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        for message in messages where message.senderId != currentUserId && message.status != .seen {
            do {
                try await db.collection("messages").document(message.id).updateData([
                    "status": Message.MessageStatus.seen.rawValue
                ])
            } catch {
                print("DEBUG: Failed to mark message as seen: \(error.localizedDescription)")
            }
        }
    }
    
    func sendMessage(_ message: Message) async throws {
        do {
            // First, ensure the conversation exists
            let conversationDoc = try await db.collection("conversations").document(message.conversationId).getDocument()
            
            if !conversationDoc.exists {
                // If conversation doesn't exist, create it
                guard let currentUserId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "MessageViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                }
                
                // Extract itemId from conversationId
                let components = message.conversationId.components(separatedBy: "_")
                let itemId = components.count >= 3 ? components[2] : ""
                
                // Create participants dictionary separately to avoid duplicate keys
                var participants: [String: Bool] = [:]
                participants[currentUserId] = true
                participants[message.senderId] = true
                
                let conversationData: [String: Any] = [
                    "participants": participants,
                    "otherUserName": message.senderName,
                    "lastMessage": message.text ?? "Image",
                    "lastMessageTimestamp": Timestamp(date: Date()),
                    "itemId": itemId,
                    "itemTitle": "Item",
                    "unreadCount": 0
                ]
                
                // Create the conversation document
                try await db.collection("conversations").document(message.conversationId).setData(conversationData)
            }
            
            // Create message data with timestamp
            let timestamp = Timestamp(date: Date())
            var messageData = try Firestore.Encoder().encode(message)
            messageData["timestamp"] = timestamp
            
            // Add the message with the generated ID
            try await db.collection("messages").document(message.id).setData(messageData)
            
            // Update conversation's last message
            try await db.collection("conversations").document(message.conversationId).updateData([
                "lastMessage": message.text ?? "Image",
                "lastMessageTimestamp": timestamp
            ])
            
            // Increment unread count for the other participant
            let conversation = try await db.collection("conversations").document(message.conversationId).getDocument()
            if let participants = conversation.data()?["participants"] as? [String: Bool],
               let otherUserId = participants.keys.first(where: { $0 != message.senderId }) {
                try await db.collection("conversations").document(message.conversationId).updateData([
                    "unreadCount": FieldValue.increment(Int64(1))
                ])
            }
            
            // Update message status to delivered
            try await db.collection("messages").document(message.id).updateData([
                "status": Message.MessageStatus.delivered.rawValue
            ])
            
        } catch {
            print("DEBUG: Failed to send message with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func checkUserVerification(userId: String) async {
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            DispatchQueue.main.async {
                self.isOtherUserVerified = userDoc.data()?["isVerified"] as? Bool ?? false
            }
        } catch {
            print("DEBUG: Failed to check user verification status: \(error.localizedDescription)")
        }
    }
} 