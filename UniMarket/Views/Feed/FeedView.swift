import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var itemViewModel: ItemViewModel
    @State private var searchText = ""
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return itemViewModel.items
        } else {
            return itemViewModel.items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    if let university = authViewModel.currentUser?.university.name {
                        Text("Showing listings from \(university)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    
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
            }
            .navigationTitle("UniMarket")
            .searchable(text: $searchText, prompt: "Search items")
            .task {
                await loadItems()
            }
            .onAppear {
                Task {
                    await loadItems()
                }
            }
        }
    }
    
    private func loadItems() async {
        if let university = authViewModel.currentUser?.university.name {
            await itemViewModel.fetchItems(forUniversity: university)
        }
    }
}

struct ItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            if let firstImage = item.images.first, let url = URL(string: firstImage) {
                RemoteImage(url: url)
                    .frame(height: 150)
                    .clipped()
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(height: 150)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text(item.condition)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

#Preview {
    FeedView()
        .environmentObject(AuthViewModel())
        .environmentObject(ItemViewModel())
} 