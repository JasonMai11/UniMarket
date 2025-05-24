import SwiftUI
import Firebase

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    @EnvironmentObject var listingViewModel: ListingViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("Listings", systemImage: "list.bullet")
                }
                .tag(0)
            
            MessagesView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }
                .tag(1)
            
            CreateListingView()
                .tabItem {
                    Label("Sell", systemImage: "plus.circle")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(3)
        }
        .task {
            // Request notification permission
            messageViewModel.requestNotificationPermission()
            
            // Setup message notifications
            messageViewModel.setupMessageNotifications()
            
            // Fetch initial data
            await messageViewModel.fetchConversations()
            await listingViewModel.fetchListings()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
        .environmentObject(MessageViewModel())
        .environmentObject(ListingViewModel())
} 