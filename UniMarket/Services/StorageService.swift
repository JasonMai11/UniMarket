import Foundation
import FirebaseStorage
import UIKit
import Network

class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    private let maxImageSize: Int = 5 * 1024 * 1024 // 5MB
    
    private init() {}
    
    private func checkNetworkConnection() async throws {
        let monitor = NWPathMonitor()
        let path = try await withCheckedThrowingContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                monitor.cancel()
                continuation.resume(returning: path)
            }
            monitor.start(queue: DispatchQueue.global())
        }
        
        guard path.status == .satisfied else {
            throw NSError(domain: "StorageService", code: -5, userInfo: [NSLocalizedDescriptionKey: "No network connection available"])
        }
    }
    
    private func validateImage(_ image: UIImage) throws -> Data {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "StorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        if imageData.count > maxImageSize {
            // Try with lower quality if image is too large
            guard let compressedData = image.jpegData(compressionQuality: 0.3) else {
                throw NSError(domain: "StorageService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Image is too large and cannot be compressed"])
            }
            return compressedData
        }
        
        return imageData
    }
    
    func uploadImage(_ image: UIImage, userId: String) async throws -> String {
        // Check network connection first
        try await checkNetworkConnection()
        
        // Validate and prepare image data
        let imageData = try validateImage(image)
        
        let filename = "\(UUID().uuidString).jpg"
        let path = "item_images/\(userId)/\(filename)"
        print("Attempting to upload image to path: \(path)")
        
        let ref = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            _ = try await ref.putDataAsync(imageData, metadata: metadata)
            
            // Get the download URL using a different method
            let downloadURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
                ref.downloadURL { url, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = url {
                        // Ensure we're using the correct URL format
                        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
                        components.scheme = "https"
                        if let finalURL = components.url {
                            continuation.resume(returning: finalURL)
                        } else {
                            continuation.resume(throwing: NSError(domain: "StorageService", code: -9, 
                                                               userInfo: [NSLocalizedDescriptionKey: "Invalid URL format"]))
                        }
                    } else {
                        continuation.resume(throwing: NSError(domain: "StorageService", code: -9, 
                                                           userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                    }
                }
            }
            
            print("Successfully uploaded image to: \(downloadURL.absoluteString)")
            return downloadURL.absoluteString
        } catch {
            print("Failed to upload image: \(error.localizedDescription)")
            throw error
        }
    }
    
    func uploadImages(_ images: [UIImage], userId: String) async throws -> [String] {
        // Check network connection first
        try await checkNetworkConnection()
        
        var urls: [String] = []
        var failedImages: [Int] = []
        
        // First attempt to upload all images
        for (index, image) in images.enumerated() {
            do {
                let url = try await uploadImage(image, userId: userId)
                urls.append(url)
            } catch {
                print("Failed to upload image \(index): \(error.localizedDescription)")
                failedImages.append(index)
            }
        }
        
        // If any images failed, try to upload them again
        if !failedImages.isEmpty {
            print("Retrying \(failedImages.count) failed images...")
            for index in failedImages {
                do {
                    let url = try await uploadImage(images[index], userId: userId)
                    urls.append(url)
                } catch {
                    print("Failed to upload image \(index) after retry: \(error.localizedDescription)")
                    throw NSError(domain: "StorageService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to upload some images after retry"])
                }
            }
        }
        
        return urls
    }
    
    func deleteImage(url: String) async throws {
        // Check network connection first
        try await checkNetworkConnection()
        
        guard let url = URL(string: url) else { return }
        let ref = storage.reference(forURL: url.absoluteString)
        
        var retryCount = 0
        var lastError: Error?
        
        while retryCount < maxRetries {
            do {
                try await ref.delete()
                return
            } catch {
                lastError = error
                retryCount += 1
                if retryCount < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NSError(domain: "StorageService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to delete image after \(maxRetries) attempts"])
    }
} 