import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    @State private var showingDeleteConfirmation = false
    @State private var showingVerification = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authViewModel.currentUser {
                        HStack {
                            if let profileImageURL = user.profileImageURL,
                               let url = URL(string: profileImageURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(user.fullName)
                                        .font(.headline)
                                    if user.isVerified {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Text(user.university.name)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                if let verificationEmail = user.verificationEmail {
                                    Text("Verified with: \(verificationEmail)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Account")) {
                    NavigationLink(destination: UserListingsView()) {
                        Label("Your Listings", systemImage: "list.bullet")
                    }
                    
                    Button(action: {
                        showingEditProfile = true
                    }) {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    
                    if let user = authViewModel.currentUser, !user.isVerified {
                        Button(action: {
                            showingVerification = true
                        }) {
                            Label("Verify Student Email", systemImage: "checkmark.seal")
                        }
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button(action: {
                        authViewModel.signOut()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Account", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                if let user = authViewModel.currentUser {
                    EditProfileView(user: user)
                }
            }
            .sheet(isPresented: $showingVerification) {
                EmailVerificationView()
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        try? await authViewModel.deleteAccount()
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var fullName = ""
    @State private var selectedUniversity: University?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isUpdating = false
    
    let user: User
    
    init(user: User) {
        self.user = user
        _fullName = State(initialValue: user.fullName)
        _selectedUniversity = State(initialValue: user.university)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $fullName)
                }
                
                Section(header: Text("University")) {
                    UniversitySearchView(selectedUniversity: $selectedUniversity)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await updateProfile()
                        }
                    }) {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .disabled(isUpdating || fullName.isEmpty || selectedUniversity == nil)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateProfile() async {
        guard let university = selectedUniversity else { return }
        
        isUpdating = true
        
        do {
            try await authViewModel.updateUserProfile(
                userId: user.id ?? "",
                fullName: fullName,
                university: university
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isUpdating = false
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthViewModel())
} 