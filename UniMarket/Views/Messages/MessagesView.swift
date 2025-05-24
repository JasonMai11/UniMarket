import SwiftUI

struct MessagesView: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.conversations.isEmpty {
                    ContentUnavailableView(
                        "No Messages",
                        systemImage: "message",
                        description: Text("Your conversations will appear here")
                    )
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .refreshable {
                await viewModel.fetchConversations()
            }
        }
    }
}

#Preview {
    MessagesView()
        .environmentObject(MessageViewModel())
        .environmentObject(AuthViewModel())
} 