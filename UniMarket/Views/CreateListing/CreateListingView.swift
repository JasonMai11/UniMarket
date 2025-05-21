import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage

struct CreateListingView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var itemViewModel: ItemViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var category = ""
    @State private var condition = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var uploadedImageUrls: [String] = []
    @State private var showingImagePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isUploading = false
    @State private var selectedUIImage: [UIImage] = []
    @State private var showingSuccess = false
    
    let categories = ["Electronics", "Books", "Furniture", "Clothing", "Sports", "Other"]
    let conditions = ["New", "Like New", "Good", "Fair", "Poor"]
    
    private func clearForm() {
        title = ""
        description = ""
        price = ""
        category = ""
        condition = ""
        selectedImages = []
        uploadedImageUrls = []
        selectedUIImage = []
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(5...)
                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $category) {
                        Text("Select Category").tag("")
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    
                    Picker("Condition", selection: $condition) {
                        Text("Select Condition").tag("")
                        ForEach(conditions, id: \.self) { condition in
                            Text(condition).tag(condition)
                        }
                    }
                }
                
                Section(header: Text("Photos")) {
                    PhotosPicker(selection: $selectedImages,
                               maxSelectionCount: 5,
                               matching: .images) {
                        Label("Select Photos", systemImage: "photo.on.rectangle")
                    }
                    
                    if !uploadedImageUrls.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(uploadedImageUrls, id: \.self) { urlString in
                                    if let url = URL(string: urlString) {
                                        RemoteImage(url: url)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                    } else {
                                        Text("Invalid URL")
                                            .foregroundColor(.red)
                                            .frame(width: 100, height: 100)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        Task {
                            await createListing()
                        }
                    }) {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Create Listing")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isUploading || !isFormValid)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray)
                }
            }
            .navigationTitle("Create Listing")
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    clearForm()
                    dismiss()
                }
            } message: {
                Text("Your listing has been created successfully!")
            }
            .onChange(of: selectedImages) { newValue in
                Task {
                    await loadTransferable(from: newValue)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty &&
        !description.isEmpty &&
        !price.isEmpty &&
        !category.isEmpty &&
        !condition.isEmpty &&
        !uploadedImageUrls.isEmpty &&
        Double(price) != nil
    }
    
    private func loadTransferable(from imageSelections: [PhotosPickerItem]) async {
        do {
            var images: [UIImage] = []
            for imageSelection in imageSelections {
                if let data = try await imageSelection.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    images.append(image)
                }
            }
            selectedUIImage = images
            await uploadImages()
        } catch {
            errorMessage = "Failed to load images: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func uploadImages() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            showingError = true
            return
        }
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            uploadedImageUrls = try await StorageService.shared.uploadImages(selectedUIImage, userId: userId)
        } catch {
            errorMessage = "Failed to upload images: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    private func createListing() async {
        guard let priceDouble = Double(price),
              let currentUser = Auth.auth().currentUser,
              let user = authViewModel.currentUser else {
            errorMessage = "Invalid price or user information"
            showingError = true
            return
        }
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            try await itemViewModel.createItem(
                title: title,
                description: description,
                price: priceDouble,
                category: category,
                condition: condition,
                images: uploadedImageUrls,
                sellerId: currentUser.uid,
                sellerName: user.fullName,
                university: user.university.name
            )
            showingSuccess = true
        } catch {
            errorMessage = "Failed to create listing: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct RemoteImage: View {
    let url: URL
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?
    @State private var retryCount = 0
    private let maxRetries = 3
    private let storage = Storage.storage()
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            } else if error != nil {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("Failed to load image")
                        .font(.caption)
                        .foregroundColor(.red)
                    if retryCount < maxRetries {
                        Button("Retry") {
                            retryCount += 1
                            loadImage()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .frame(width: 100, height: 100)
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        error = nil
        
        // Get the storage reference from the URL
        let storageRef = storage.reference(forURL: url.absoluteString)
        
        // Download the image data
        storageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.error = error
                    print("Failed to load image: \(error.localizedDescription)")
                    print("URL: \(url.absoluteString)")
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    self.error = NSError(domain: "RemoteImage", code: -1, 
                                       userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                    print("Failed to load image: Invalid image data")
                    print("URL: \(url.absoluteString)")
                    return
                }
                
                self.image = image
            }
        }
    }
}

#Preview {
    CreateListingView()
        .environmentObject(AuthViewModel())
        .environmentObject(ItemViewModel())
} 