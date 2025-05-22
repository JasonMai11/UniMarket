//
//  ContentView.swift
//  UniMarket
//
//  Created by Jason Mai on 5/21/25.
//

import SwiftUI
import Firebase

struct ContentView: View {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var messageViewModel = MessageViewModel()
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(messageViewModel)
                    .task {
                        await messageViewModel.fetchConversations()
                    }
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var messageViewModel: MessageViewModel
    
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Label("Listings", systemImage: "list.bullet")
                }
            
            MessageView()
                .tabItem {
                    Label("Messages", systemImage: "message")
                }
            
            CreateListingView()
                .tabItem {
                    Label("Sell", systemImage: "plus.circle")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    ContentView()
}
