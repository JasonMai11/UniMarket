//
//  ContentView.swift
//  UniMarket
//
//  Created by Jason Mai on 5/21/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var messageViewModel = MessageViewModel()
    
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Image(systemName: "house")
                    Text("Feed")
                }
            
            MessageView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Messages")
                }
                .badge(messageViewModel.unreadCount)
            
            CreateListingView()
                .tabItem {
                    Image(systemName: "plus.circle")
                    Text("Sell")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
        }
        .onAppear {
            if let userId = authViewModel.currentUser?.id {
                Task {
                    await messageViewModel.fetchConversations(forUserId: userId)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(ItemViewModel())
}
