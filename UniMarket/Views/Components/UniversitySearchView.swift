import SwiftUI

struct UniversitySearchView: View {
    @Binding var selectedUniversity: University?
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSearching = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("University")
                .font(.headline)
            
            Button(action: {
                isSearching = true
            }) {
                HStack {
                    Text(selectedUniversity?.name ?? "Select University")
                        .foregroundColor(selectedUniversity == nil ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $isSearching) {
            NavigationView {
                List {
                    ForEach(authViewModel.filteredUniversities) { university in
                        Button(action: {
                            selectedUniversity = university
                            isSearching = false
                        }) {
                            Text(university.name)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .searchable(text: $authViewModel.searchQuery, prompt: "Search universities")
                .onChange(of: authViewModel.searchQuery) { newValue in
                    authViewModel.updateSearchQuery(newValue)
                }
                .navigationTitle("Select University")
                .navigationBarItems(trailing: Button("Cancel") {
                    isSearching = false
                })
            }
        }
    }
}

#Preview {
    UniversitySearchView(selectedUniversity: .constant(nil))
        .environmentObject(AuthViewModel())
} 