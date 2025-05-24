import SwiftUI

struct ItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image container
            if let firstImage = item.images.first, let url = URL(string: firstImage) {
                RemoteImage(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
            }
            
            // Content container
            VStack(alignment: .leading, spacing: 8) {
                // Title and verified badge
                HStack(alignment: .top, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if item.isSellerVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                // Condition and price
                HStack {
                    Text(item.condition)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
            }
            .padding(12)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ItemCard(item: Item(
        title: "Sample Item with a very long title that might wrap to multiple lines",
        description: "This is a sample item description",
        price: 99.99,
        category: "Electronics",
        condition: "Like New",
        images: ["https://example.com/image.jpg"],
        sellerId: "sampleSellerId",
        sellerName: "John Doe",
        university: "Sample University",
        status: .available,
        datePosted: Date(),
        isSellerVerified: true
    ))
    .frame(width: 180)
    .padding()
} 