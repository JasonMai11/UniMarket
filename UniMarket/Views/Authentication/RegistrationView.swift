import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email = ""
    @State private var fullName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedUniversity: University?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Create Account")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 15) {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        UniversitySearchView(selectedUniversity: $selectedUniversity)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button(action: {
                            if password != confirmPassword {
                                errorMessage = "Passwords do not match"
                                showError = true
                                return
                            }
                            
                            guard let university = selectedUniversity else {
                                errorMessage = "Please select a university"
                                showError = true
                                return
                            }
                            
                            Task {
                                do {
                                    try await authViewModel.createUser(
                                        email: email,
                                        password: password,
                                        fullName: fullName,
                                        university: university
                                    )
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }) {
                            Text("Sign Up")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthViewModel())
} 