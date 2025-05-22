import Foundation
import Firebase
import FirebaseFirestore
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    @Published var selectedUniversity: University?
    @Published var searchQuery = ""
    @Published var filteredUniversities: [University] = []
    @Published var isAuthenticated = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        userSession = auth.currentUser
        Task {
            await fetchUser()
        }
        filteredUniversities = University.universities
    }
    
    func signIn(withEmail email: String, password: String) async throws {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            self.userSession = result.user
            await fetchUser()
        } catch {
            print("DEBUG: Failed to sign in with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func createUser(email: String, password: String, fullName: String, university: University) async throws {
        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            self.userSession = authResult.user
            
            let user = User(
                id: authResult.user.uid,
                email: email,
                fullName: fullName,
                university: university,
                isVerified: false,
                createdAt: Date()
            )
            
            let encoder = Firestore.Encoder()
            let userData = try encoder.encode(user)
            try await db.collection("users").document(authResult.user.uid).setData(userData)
            
            self.currentUser = user
        } catch {
            print("DEBUG: Failed to create user with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateUserProfile(userId: String, fullName: String, university: University) async throws {
        do {
            let userData: [String: Any] = [
                "fullName": fullName,
                "university": university.name
            ]
            
            try await db.collection("users").document(userId).updateData(userData)
            await fetchUser()
        } catch {
            print("DEBUG: Failed to update user profile with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() {
        do {
            try auth.signOut()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("DEBUG: Failed to sign out with error \(error.localizedDescription)")
        }
    }
    
    func deleteAccount() async throws {
        guard let user = auth.currentUser else { return }
        
        do {
            try await user.delete()
            self.userSession = nil
            self.currentUser = nil
        } catch {
            print("DEBUG: Failed to delete account with error \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchUser() async {
        guard let uid = auth.currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                let decoder = Firestore.Decoder()
                self.currentUser = try decoder.decode(User.self, from: data)
                print("DEBUG: Successfully fetched user with university: \(self.currentUser?.university.name ?? "none")")
            } else {
                print("DEBUG: No user data found for ID: \(uid)")
            }
        } catch {
            print("DEBUG: Failed to fetch user with error \(error.localizedDescription)")
        }
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        filteredUniversities = University.searchUniversities(query: query)
    }
    
    func sendVerificationCode(to email: String) async throws {
        // Generate a random 6-digit code
        let code = String(format: "%06d", Int.random(in: 0...999999))
        
        // Store the code in Firestore with a 10-minute expiration
        let verificationData: [String: Any] = [
            "code": code,
            "email": email,
            "createdAt": Timestamp(),
            "expiresAt": Timestamp(date: Date().addingTimeInterval(600)) // 10 minutes
        ]
        
        try await db.collection("verificationCodes").document(email).setData(verificationData)
        
        // TODO: Implement actual email sending service
        // For now, we'll just print the code
        print("DEBUG: Verification code for \(email): \(code)")
    }
    
    func verifyEmail(email: String, code: String) async throws {
        guard let userId = currentUser?.id else { return }
        
        // Get the stored verification code
        let doc = try await db.collection("verificationCodes").document(email).getDocument()
        guard let data = doc.data(),
              let storedCode = data["code"] as? String,
              let expiresAt = data["expiresAt"] as? Timestamp else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code"])
        }
        
        // Check if the code has expired
        if expiresAt.dateValue() < Date() {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Verification code has expired"])
        }
        
        // Verify the code
        guard code == storedCode else {
            throw NSError(domain: "AuthViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid verification code"])
        }
        
        // Update user's verification status
        try await db.collection("users").document(userId).updateData([
            "isVerified": true,
            "verificationEmail": email
        ])
        
        // Delete the used verification code
        try await db.collection("verificationCodes").document(email).delete()
        
        // Update local user object
        if var user = currentUser {
            user.isVerified = true
            user.verificationEmail = email
            currentUser = user
        }
    }
} 