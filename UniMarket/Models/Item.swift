import Foundation
import FirebaseFirestore

struct Item: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var price: Double
    var category: String
    var condition: String
    var images: [String]
    var sellerId: String
    var sellerName: String
    var university: String
    var status: ItemStatus
    var datePosted: Date
    var isSellerVerified: Bool
    
    enum ItemStatus: String, Codable {
        case available
        case sold
        case pending
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case price
        case category
        case condition
        case images
        case sellerId
        case sellerName
        case university
        case status
        case datePosted
        case isSellerVerified
    }
} 