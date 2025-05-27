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
    @State private var timeRemaining = 600 // 10 minutes in seconds
    @State private var timer: Timer?
    @State private var emailValidationMessage = ""
    @State private var isEmailValid = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("School Email Verification")) {
                    Text("Please enter your university (.edu) email address to verify your student status.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("School Email", text: $schoolEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disabled(codeSent)
                            .onChange(of: schoolEmail) { newValue in
                                validateEmail(newValue)
                            }
                        
                        if !emailValidationMessage.isEmpty {
                            Text(emailValidationMessage)
                                .font(.caption)
                                .foregroundColor(isEmailValid ? .green : .red)
                        }
                    }
                    
                    if codeSent {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Verification Code", text: $verificationCode)
                                .textContentType(.oneTimeCode)
                                .keyboardType(.numberPad)
                            
                            if timeRemaining > 0 {
                                Text("Code expires in: \(timeString(from: timeRemaining))")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Text("Code expired")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            
                            if timeRemaining <= 0 {
                                Button("Resend Code") {
                                    Task {
                                        await resendCode()
                                    }
                                }
                                .disabled(isSendingCode)
                            }
                        }
                    }
                }
                
                Section {
                    if !codeSent {
                        Button(action: {
                            Task {
                                await sendVerificationCode()
                            }
                        }) {
                            HStack {
                                if isSendingCode {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Sending Code...")
                                } else {
                                    Text("Send Verification Code")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isSendingCode || !isEmailValid)
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button(action: {
                            Task {
                                await verifyCode()
                            }
                        }) {
                            HStack {
                                if isVerifying {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Verifying...")
                                } else {
                                    Text("Verify Code")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(isVerifying || verificationCode.isEmpty || timeRemaining <= 0)
                        .buttonStyle(.borderedProminent)
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
    
    private func validateEmail(_ email: String) {
        if email.isEmpty {
            emailValidationMessage = ""
            isEmailValid = false
        } else if !email.contains("@") {
            emailValidationMessage = "Please enter a valid email address"
            isEmailValid = false
        } else if !email.hasSuffix(".edu") {
            emailValidationMessage = "Please use your university (.edu) email address"
            isEmailValid = false
        } else {
            emailValidationMessage = "Valid .edu email address"
            isEmailValid = true
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func startTimer() {
        timeRemaining = 600 // Reset to 10 minutes
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
            }
        }
    }
    
    private func sendVerificationCode() async {
        isSendingCode = true
        defer { isSendingCode = false }
        
        do {
            try await authViewModel.sendVerificationCode(to: schoolEmail)
            codeSent = true
            startTimer()
        } catch {
            errorMessage = getErrorMessage(for: error)
            showingError = true
        }
    }
    
    private func resendCode() async {
        isSendingCode = true
        defer { isSendingCode = false }
        
        do {
            try await authViewModel.sendVerificationCode(to: schoolEmail)
            startTimer()
        } catch {
            errorMessage = getErrorMessage(for: error)
            showingError = true
        }
    }
    
    private func verifyCode() async {
        isVerifying = true
        defer { isVerifying = false }
        
        do {
            try await authViewModel.verifyEmail(email: schoolEmail, code: verificationCode)
            timer?.invalidate()
            dismiss()
        } catch {
            errorMessage = getErrorMessage(for: error)
            showingError = true
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        // Add specific error messages based on the error type
        if let error = error as? AuthError {
            switch error {
            case .invalidEmail:
                return "Please enter a valid .edu email address"
            case .invalidCode:
                return "Invalid verification code. Please try again"
            case .codeExpired:
                return "Verification code has expired. Please request a new code"
            case .networkError:
                return "Network error. Please check your connection and try again"
            case .unknown:
                return "An unexpected error occurred. Please try again"
            }
        }
        return error.localizedDescription
    }
}

// Add this enum to your AuthViewModel file
enum AuthError: Error {
    case invalidEmail
    case invalidCode
    case codeExpired
    case networkError
    case unknown
} 