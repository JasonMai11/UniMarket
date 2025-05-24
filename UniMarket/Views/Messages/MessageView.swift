import SwiftUI

struct MessageView: View {
    @EnvironmentObject var viewModel: MessageViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.conversations) { conversation in
                    NavigationLink(destination: ChatView(conversation: conversation)) {
                        ConversationRow(conversation: conversation)
                    }
                }
            }
            .navigationTitle("Messages")
            .refreshable {
                await viewModel.fetchConversations()
            }
        }
        .task {
            await viewModel.fetchConversations()
        }
    }
}

#Preview {
    MessageView()
        .environmentObject(MessageViewModel())
        .environmentObject(AuthViewModel())
} 