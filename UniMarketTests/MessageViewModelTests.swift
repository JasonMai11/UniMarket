import XCTest
@testable import UniMarket
import FirebaseFirestore
import FirebaseAuth

@MainActor
final class MessageViewModelTests: XCTestCase {
    var messageViewModel: MessageViewModel!
    var authViewModel: AuthViewModel!
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    override func setUp() async throws {
        try await super.setUp()
        messageViewModel = MessageViewModel()
        authViewModel = AuthViewModel()
        
        // Create test user if it doesn't exist
        do {
            try await auth.signIn(withEmail: "test@test.com", password: "test123")
        } catch {
            // If sign in fails, create the user
            try await auth.createUser(withEmail: "test@test.com", password: "test123")
            try await auth.signIn(withEmail: "test@test.com", password: "test123")
        }
    }
    
    override func tearDown() async throws {
        // Sign out test user
        try? auth.signOut()
        messageViewModel = nil
        authViewModel = nil
        try await super.tearDown()
    }
    
    func testSendAndFetchMessage() async throws {
        // Create test users in Firestore
        let sellerData: [String: Any] = [
            "id": "test_seller_id",
            "email": "seller@test.com",
            "fullName": "Test Seller",
            "university": "Test University",
            "createdAt": Timestamp(date: Date())
        ]
        
        let buyerData: [String: Any] = [
            "id": "test_buyer_id",
            "email": "buyer@test.com",
            "fullName": "Test Buyer",
            "university": "Test University",
            "createdAt": Timestamp(date: Date())
        ]
        
        // Add test users to Firestore
        try await db.collection("users").document("test_seller_id").setData(sellerData)
        try await db.collection("users").document("test_buyer_id").setData(buyerData)
        
        // Create test item
        let item = Item(
            id: "test_item_id",
            title: "Test Item",
            description: "Test Description",
            price: 99.99,
            category: "Test Category",
            condition: "New",
            images: [],
            sellerId: "test_seller_id",
            sellerName: "Test Seller",
            university: "Test University",
            status: .available,
            datePosted: Date()
        )
        
        // Create test message
        let message = Message(
            senderId: "test_buyer_id",
            senderName: "Test Buyer",
            receiverId: "test_seller_id",
            receiverName: "Test Seller",
            content: "Hello, I'm interested in your item!",
            timestamp: Date(),
            itemId: "test_item_id",
            itemTitle: "Test Item"
        )
        
        // Test sending message
        do {
            try await messageViewModel.sendMessage(message)
            
            // Test fetching messages
            await messageViewModel.fetchMessages(
                forItemId: "test_item_id",
                between: "test_buyer_id",
                and: "test_seller_id"
            )
            
            // Verify message was sent and fetched
            XCTAssertFalse(messageViewModel.messages.isEmpty)
            XCTAssertEqual(messageViewModel.messages.first?.content, message.content)
            XCTAssertEqual(messageViewModel.messages.first?.senderId, message.senderId)
            XCTAssertEqual(messageViewModel.messages.first?.receiverId, message.receiverId)
            
            // Test fetching conversations
            await messageViewModel.fetchConversations(forUserId: "test_buyer_id")
            
            // Verify conversation was created
            XCTAssertFalse(messageViewModel.conversations.isEmpty)
            XCTAssertEqual(messageViewModel.conversations.first?.otherUserId, "test_seller_id")
            XCTAssertEqual(messageViewModel.conversations.first?.itemTitle, "Test Item")
            
        } catch {
            XCTFail("Failed to send or fetch message: \(error.localizedDescription)")
        }
        
        // Clean up test data
        try await db.collection("users").document("test_seller_id").delete()
        try await db.collection("users").document("test_buyer_id").delete()
    }
} 