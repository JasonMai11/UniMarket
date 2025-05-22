import SwiftUI

struct UserListingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var itemViewModel = ItemViewModel()
    @State private var selectedTab = 0
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            // Custom segmented control
            HStack {
                Button(action: { selectedTab = 0 }) {
                    VStack {
                        Text("Active")
                            .font(.headline)
                            .foregroundColor(selectedTab == 0 ? .blue : .gray)
                        Rectangle()
                            .fill(selectedTab == 0 ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
                
                Button(action: { selectedTab = 1 }) {
                    VStack {
                        Text("Sold")
                            .font(.headline)
                            .foregroundColor(selectedTab == 1 ? .blue : .gray)
                        Rectangle()
                            .fill(selectedTab == 1 ? Color.blue : Color.clear)
                            .frame(height: 2)
                    }
                }
            }
            .padding()
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredItems) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                ItemCard(item: item)
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await loadItems()
                }
            }
        }
        .navigationTitle("Your Listings")
        .task {
            await loadItems()
        }
    }
    
    private var filteredItems: [Item] {
        let status: Item.ItemStatus = selectedTab == 0 ? .available : .sold
        return itemViewModel.items.filter { $0.status == status }
    }
    
    private func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        if let userId = authViewModel.currentUser?.id {
            do {
                itemViewModel.items = try await itemViewModel.fetchUserListings(userId: userId)
            } catch {
                print("DEBUG: Failed to fetch user listings with error \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NavigationView {
        UserListingsView()
            .environmentObject(AuthViewModel())
    }
} 