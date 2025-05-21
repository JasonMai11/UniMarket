import Foundation
import Firebase
import FirebaseFirestore

class ItemViewModel: ObservableObject {
    @Published var items = [Item]()
    private let db = Firestore.firestore()
    
    func fetchItems(forUniversity university: String) async {
        do {
            let snapshot = try await db.collection("items")
                .whereField("university", isEqualTo: university)
                .whereField("status", isEqualTo: Item.ItemStatus.available.rawValue)
                .order(by: "datePosted", descending: true)
                .getDocuments()
            
            self.items = snapshot.documents.compactMap({ try? $0.data(as: Item.self) })
        } catch {
            print("DEBUG: Failed to fetch items with error \(error.localizedDescription)")
        }
    }
    
    func createItem(title: String, description: String, price: Double, category: String, condition: String, images: [String], sellerId: String, sellerName: String, university: String) async throws {
        let item = Item(title: title,
                       description: description,
                       price: price,
                       category: category,
                       condition: condition,
                       images: images,
                       sellerId: sellerId,
                       sellerName: sellerName,
                       university: university,
                       status: .available,
                       datePosted: Date())
        
        let encodedItem = try Firestore.Encoder().encode(item)
        try await db.collection("items").addDocument(data: encodedItem)
        await fetchItems(forUniversity: university)
    }
    
    func updateItemStatus(itemId: String, newStatus: Item.ItemStatus) async throws {
        try await db.collection("items").document(itemId).updateData([
            "status": newStatus.rawValue
        ])
        
        if let university = items.first(where: { $0.id == itemId })?.university {
            await fetchItems(forUniversity: university)
        }
    }
    
    func deleteItem(itemId: String) async throws {
        try await db.collection("items").document(itemId).delete()
        
        if let university = items.first(where: { $0.id == itemId })?.university {
            await fetchItems(forUniversity: university)
        }
    }
} 