import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingEditProfile = false
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text(authViewModel.currentUser?.fullName ?? "")
                            .font(.headline)
                        Spacer()
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("University Information")) {
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .foregroundColor(.blue)
                        Text(authViewModel.currentUser?.university.name ?? "")
                            .font(.headline)
                    }
                }
                
                Section {
                    Button("Edit Profile") {
                        showingEditProfile = true
                    }
                    
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                }
                
                Section {
                    Button("Delete Account") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
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
            .onAppear {
                if let user = authViewModel.currentUser {
                    fullName = user.fullName
                    selectedUniversity = user.university
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateProfile() async {
        guard let user = authViewModel.currentUser,
              let university = selectedUniversity else { return }
        
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