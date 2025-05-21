import SwiftUI

struct ItemDetailView: View {
    let item: Item
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingContactSheet = false
    
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
                    Text(item.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
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
            if item.sellerId != authViewModel.currentUser?.id {
                Button("Contact Seller") {
                    showingContactSheet = true
                }
            }
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
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ItemDetailView(item: Item(
            title: "Sample Item",
            description: "This is a sample item description",
            price: 99.99,
            category: "Electronics",
            condition: "Like New",
            images: [],
            sellerId: "123",
            sellerName: "John Doe",
            university: "Sample University",
            status: .available,
            datePosted: Date()
        ))
        .environmentObject(AuthViewModel())
    }
} 