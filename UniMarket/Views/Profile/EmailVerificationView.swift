import SwiftUI

struct EmailVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var schoolEmail = ""
    @State private var verificationCode = ""
    @State private var isSendingCode = false
    @State private var isVerifying = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var codeSent = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("School Email Verification")) {
                    Text("Please enter your university (.edu) email address to verify your student status.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                    
                    TextField("School Email", text: $schoolEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disabled(codeSent)
                    
                    if codeSent {
                        TextField("Verification Code", text: $verificationCode)
                            .textContentType(.oneTimeCode)
                            .keyboardType(.numberPad)
                    }
                }
                
                Section {
                    if !codeSent {
                        Button(action: {
                            Task {
                                await sendVerificationCode()
                            }
                        }) {
                            if isSendingCode {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Send Verification Code")
                            }
                        }
                        .disabled(isSendingCode || schoolEmail.isEmpty)
                    } else {
                        Button(action: {
                            Task {
                                await verifyCode()
                            }
                        }) {
                            if isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Verify Code")
                            }
                        }
                        .disabled(isVerifying || verificationCode.isEmpty)
                    }
                }
            }
            .navigationTitle("Email Verification")
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
    
    private func sendVerificationCode() async {
        isSendingCode = true
        defer { isSendingCode = false }
        
        do {
            try await authViewModel.sendVerificationCode(to: schoolEmail)
            codeSent = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    private func verifyCode() async {
        isVerifying = true
        defer { isVerifying = false }
        
        do {
            try await authViewModel.verifyEmail(email: schoolEmail, code: verificationCode)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
} 