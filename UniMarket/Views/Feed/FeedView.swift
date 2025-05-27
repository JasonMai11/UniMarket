import SwiftUI

struct FeedView: View {
    @EnvironmentObject var listingViewModel: ListingViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var searchText = ""
    @State private var showingFilters = false
    
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 180), spacing: 16)
    ]
    
    var filteredListings: [Item] {
        if searchText.isEmpty {
            return listingViewModel.listings
        } else {
            return listingViewModel.listings.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                if let university = authViewModel.currentUser?.university.name {
                    Text("Showing listings from \(university)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                Group {
                    if listingViewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredListings.isEmpty {
                        ContentUnavailableView(
                            "No Listings",
                            systemImage: "list.bullet",
                            description: Text("Listings will appear here")
                        )
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredListings) { item in
                                    NavigationLink(destination: ItemDetailView(item: item)) {
                                        ItemCard(item: item)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                        }
                    }
                }
            }
            .navigationTitle("Listings")
            .searchable(text: $searchText, prompt: "Search listings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingFilters = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .refreshable {
                await listingViewModel.fetchListings()
            }
            .onReceive(NotificationCenter.default.publisher(for: .universityChanged)) { _ in
                Task {
                    await listingViewModel.fetchListings()
                }
            }
        }
    }
}

struct ItemRow: View {
    let item: Item
    
    var body: some View {
        HStack {
            if let imageUrl = item.images.first, let url = URL(string: imageUrl) {
                RemoteImage(url: url)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FeedView()
        .environmentObject(ListingViewModel())
        .environmentObject(AuthViewModel())
} 