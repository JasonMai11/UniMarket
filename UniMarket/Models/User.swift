import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var email: String
    var fullName: String
    var university: University
    var profileImageURL: String?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName
        case university
        case profileImageURL
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decode(String.self, forKey: .fullName)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Decode university name and find matching University object
        let universityName = try container.decode(String.self, forKey: .university)
        if let university = University.universities.first(where: { $0.name == universityName }) {
            self.university = university
        } else {
            // If university not found, create a default one with the stored name
            self.university = University(name: universityName, state: "Unknown")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(fullName, forKey: .fullName)
        try container.encodeIfPresent(profileImageURL, forKey: .profileImageURL)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(university.name, forKey: .university)
    }
} 
