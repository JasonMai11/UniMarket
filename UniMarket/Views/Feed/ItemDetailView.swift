import SwiftUI

struct ItemDetailView: View {
    let item: Item
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var itemViewModel: ItemViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @State private var showingContactSheet = false
    @State private var showingActionSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.dismiss) var dismiss
    
    var isSeller: Bool {
        item.sellerId == authViewModel.currentUser?.id
    }
    
    var body: some View {
        ScrollView {
            VStack {
                if !item.images.isEmpty {
                    TabView {
                        ForEach(item.images, id: \.self) { imageUrl in
                            if let url = URL(string: imageUrl) {
                                RemoteImage(url: url)
                                    .frame(height: 300)
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(PageTabViewStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(item.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if item.status != .available {
                            Text(item.status.rawValue.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(item.status == .sold ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundColor(item.status == .sold ? .red : .orange)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(item.description)
                        .font(.body)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Condition: \(item.condition)")
                            .font(.subheadline)
                        Text("Category: \(item.category)")
                            .font(.subheadline)
                        Text("Seller: \(item.sellerName)")
                            .font(.subheadline)
                        Text("University: \(item.university)")
                            .font(.subheadline)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSeller {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingActionSheet = true
                    }) {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            } else if item.status == .available {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Contact Seller") {
                        showingContactSheet = true
                    }
                }
            }
        }
        .confirmationDialog("Item Options", isPresented: $showingActionSheet) {
            if item.status == .available {
                Button("Mark as Sold") {
                    Task {
                        await updateItemStatus(.sold)
                    }
                }
            }
            Button("Delete Listing", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
        .alert("Delete Listing", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteItem()
                }
            }
        } message: {
            Text("Are you sure you want to delete this listing? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingContactSheet) {
            if let currentUser = authViewModel.currentUser {
                NavigationView {
                    ChatView(conversation: Conversation(
                        id: "\(min(currentUser.id ?? "", item.sellerId))_\(max(currentUser.id ?? "", item.sellerId))_\(item.id ?? "")",
                        otherUserId: item.sellerId,
                        otherUserName: item.sellerName,
                        lastMessage: "",
                        lastMessageTimestamp: Date(),
                        itemId: item.id ?? "",
                        itemTitle: item.title,
                        unreadCount: 0
                    ))
                    .environmentObject(authViewModel)
                    .environmentObject(messageViewModel)
                    .task {
                        do {
                            _ = try await messageViewModel.createConversation(
                                with: item.sellerId,
                                otherUserName: item.sellerName,
                                itemId: item.id ?? "",
                                itemTitle: item.title
                            )
                        } catch {
                            print("DEBUG: Failed to create conversation: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    private func updateItemStatus(_ status: Item.ItemStatus) async {
        do {
            try await itemViewModel.updateItemStatus(itemId: item.id ?? "", status: status)
            dismiss()
        } catch {
            errorMessage = "Failed to update item status: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func deleteItem() async {
        do {
            try await itemViewModel.deleteItem(itemId: item.id ?? "")
            dismiss()
        } catch {
            errorMessage = "Failed to delete item: \(error.localizedDescription)"
            showingError = true
        }
    }
}

#Preview {
    ItemDetailView(item: Item(
        title: "Sample Item",
        description: "This is a sample item description",
        price: 99.99,
        category: "Electronics",
        condition: "Like New",
        images: ["https://example.com/image.jpg"],
        sellerId: "sampleSellerId",
        sellerName: "John Doe",
        university: "Sample University",
        status: .available,
        datePosted: Date(),
        isSellerVerified: true
    ))
    .environmentObject(AuthViewModel())
    .environmentObject(ItemViewModel())
    .environmentObject(MessageViewModel())
} 