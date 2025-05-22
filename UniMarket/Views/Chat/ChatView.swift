import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct ChatView: View {
    let conversation: Conversation
    @EnvironmentObject var viewModel: MessageViewModel
    @State private var messageText = ""
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isUploading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            // Chat header
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(conversation.otherUserName)
                            .font(.headline)
                        
                        if viewModel.isOtherUserVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    Text(conversation.itemTitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            // Messages
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages) { _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            
            // Message input
            HStack {
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "photo")
                        .foregroundColor(.blue)
                }
                .disabled(isUploading)
                
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isUploading)
                
                Button(action: {
                    Task {
                        await sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
            }
            .padding()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                Task {
                    await uploadImage(image)
                }
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .task {
            await viewModel.fetchMessages(forConversationId: conversation.id)
            await viewModel.checkUserVerification(userId: conversation.otherUserId)
        }
    }
    
    private func sendMessage() async {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        do {
            let message = Message(
                conversationId: conversation.id,
                text: messageText,
                imageUrl: nil,
                senderId: Auth.auth().currentUser?.uid ?? "",
                senderName: authViewModel.currentUser?.fullName ?? "Unknown",
                timestamp: Date()
            )
            
            try await viewModel.sendMessage(message)
            messageText = ""
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func uploadImage(_ image: UIImage) async {
        isUploading = true
        defer { isUploading = false }
        
        do {
            let imageUrl = try await uploadImageToStorage(image)
            let message = Message(
                conversationId: conversation.id,
                text: nil,
                imageUrl: imageUrl,
                senderId: Auth.auth().currentUser?.uid ?? "",
                senderName: authViewModel.currentUser?.fullName ?? "Unknown",
                timestamp: Date()
            )
            
            try await viewModel.sendMessage(message)
        } catch {
            errorMessage = "Failed to upload image: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func uploadImageToStorage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "ChatView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }
        
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("chat_images/\(UUID().uuidString).jpg")
        
        _ = try await imageRef.putDataAsync(imageData)
        let url = try await imageRef.downloadURL()
        return url.absoluteString
    }
}

struct MessageBubble: View {
    let message: Message
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var isCurrentUser: Bool {
        message.senderId == authViewModel.currentUser?.id
    }
    
    var statusIcon: String {
        switch message.status {
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .seen:
            return "checkmark.circle.fill"
        }
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading) {
                if let text = message.text {
                    Text(text)
                        .padding()
                        .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(isCurrentUser ? .white : .primary)
                        .cornerRadius(20)
                }
                
                if let imageUrl = message.imageUrl, let url = URL(string: imageUrl) {
                    RemoteImage(url: url)
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(20)
                }
                
                HStack(spacing: 4) {
                    if isCurrentUser {
                        Image(systemName: statusIcon)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

#Preview {
    ChatView(conversation: Conversation(
        id: "preview",
        otherUserId: "other",
        otherUserName: "John Doe",
        lastMessage: "Hello!",
        lastMessageTimestamp: Date(),
        itemId: "item1",
        itemTitle: "Sample Item",
        unreadCount: 0
    ))
    .environmentObject(AuthViewModel())
    .environmentObject(MessageViewModel())
} 