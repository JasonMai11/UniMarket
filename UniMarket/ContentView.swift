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
    @StateObject var listingViewModel = ListingViewModel()
    
    var body: some View {
        Group {
            if authViewModel.userSession != nil {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(messageViewModel)
                    .environmentObject(listingViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
