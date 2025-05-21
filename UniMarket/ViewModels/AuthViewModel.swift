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
            
            let userData: [String: Any] = [
                "id": authResult.user.uid,
                "email": email,
                "fullName": fullName,
                "university": university.name,
                "createdAt": Timestamp(date: Date())
            ]
            
            try await db.collection("users").document(authResult.user.uid).setData(userData)
            await fetchUser()
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
            }
        } catch {
            print("DEBUG: Failed to fetch user with error \(error.localizedDescription)")
        }
    }
    
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        filteredUniversities = University.searchUniversities(query: query)
    }
} 