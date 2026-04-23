import Foundation
import FirebaseFirestore

struct Favorite: Identifiable, Codable {
    @DocumentID var id: String?
    var userID: String
    var productID: String
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case productID
        case createdAt
    }
}