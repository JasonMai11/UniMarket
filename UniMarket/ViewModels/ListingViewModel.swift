import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

class ListingViewModel: ObservableObject {
    @Published var listings: [Item] = []
    @Published var isLoading = false
    @Published var error: Error?
    private let db = Firestore.firestore()
    
    func fetchListings() async {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let snapshot = try await db.collection("items")
                .whereField("status", isEqualTo: Item.ItemStatus.available.rawValue)
                .order(by: "datePosted", descending: true)
                .getDocuments()
            
            self.listings = snapshot.documents.compactMap { try? $0.data(as: Item.self) }
        } catch {
            print("DEBUG: Failed to fetch listings: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func createListing(title: String, description: String, price: Double, category: String, condition: String, images: [String], sellerId: String, sellerName: String, university: String) async throws {
        // Get seller's verification status
        let userDoc = try await db.collection("users").document(sellerId).getDocument()
        let isSellerVerified = userDoc.data()?["isVerified"] as? Bool ?? false
        
        let item = Item(
            title: title,
            description: description,
            price: price,
            category: category,
            condition: condition,
            images: images,
            sellerId: sellerId,
            sellerName: sellerName,
            university: university,
            status: .available,
            datePosted: Date(),
            isSellerVerified: isSellerVerified
        )
        
        let encodedItem = try Firestore.Encoder().encode(item)
        try await db.collection("items").addDocument(data: encodedItem)
        await fetchListings()
    }
    
    func updateListingStatus(itemId: String, status: Item.ItemStatus) async throws {
        guard let item = listings.first(where: { $0.id == itemId }) else {
            throw NSError(domain: "ListingViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
        }
        
        try await db.collection("items").document(itemId).updateData([
            "status": status.rawValue
        ])
        
        await fetchListings()
    }
    
    func deleteListing(itemId: String) async throws {
        guard let item = listings.first(where: { $0.id == itemId }) else {
            throw NSError(domain: "ListingViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
        }
        
        try await db.collection("items").document(itemId).delete()
        await fetchListings()
    }
    
    func fetchUserListings(userId: String) async throws -> [Item] {
        let snapshot = try await db.collection("items")
            .whereField("sellerId", isEqualTo: userId)
            .order(by: "datePosted", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Item.self) }
    }
} 