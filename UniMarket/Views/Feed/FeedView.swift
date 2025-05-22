import SwiftUI

struct FeedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var itemViewModel = ItemViewModel()
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    if let university = authViewModel.currentUser?.university.name {
                        Text("Showing listings from \(university)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 50)
                    } else if itemViewModel.items.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No items found")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(itemViewModel.items) { item in
                                NavigationLink(destination: ItemDetailView(item: item)) {
                                    ItemCard(item: item)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .refreshable {
                await loadItems()
            }
            .navigationTitle("Listings")
        }
        .task {
            await loadItems()
        }
        .onAppear {
            Task {
                await loadItems()
            }
        }
    }
    
    private func loadItems() async {
        guard let university = authViewModel.currentUser?.university.name else {
            print("DEBUG: No university found for current user")
            return
        }
        
        print("DEBUG: Loading items for university: \(university)")
        isLoading = true
        defer { isLoading = false }
        
        await itemViewModel.fetchItems(forUniversity: university)
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
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if item.isSellerVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                HStack {
                    Text(item.condition)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if item.isSellerVerified {
                        Text("Verified Student")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
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