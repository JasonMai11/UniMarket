import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var email: String
    var fullName: String
    var university: University
    var profileImageURL: String?
    var isVerified: Bool
    var verificationEmail: String?
    var createdAt: Date
    
    init(id: String? = nil, email: String, fullName: String, university: University, profileImageURL: String? = nil, isVerified: Bool = false, verificationEmail: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.fullName = fullName
        self.university = university
        self.profileImageURL = profileImageURL
        self.isVerified = isVerified
        self.verificationEmail = verificationEmail
        self.createdAt = createdAt
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id &&
        lhs.email == rhs.email &&
        lhs.fullName == rhs.fullName &&
        lhs.university == rhs.university &&
        lhs.profileImageURL == rhs.profileImageURL &&
        lhs.isVerified == rhs.isVerified &&
        lhs.verificationEmail == rhs.verificationEmail &&
        lhs.createdAt == rhs.createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName
        case university
        case profileImageURL
        case isVerified
        case verificationEmail
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        fullName = try container.decode(String.self, forKey: .fullName)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
        verificationEmail = try container.decodeIfPresent(String.self, forKey: .verificationEmail)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        
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
        try container.encode(isVerified, forKey: .isVerified)
        try container.encodeIfPresent(verificationEmail, forKey: .verificationEmail)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(university.name, forKey: .university)
    }
} 
