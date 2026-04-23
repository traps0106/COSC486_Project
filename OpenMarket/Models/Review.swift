import Foundation
import FirebaseFirestore

struct Review: Identifiable, Codable {
    @DocumentID var id: String?
    var productID: String
    var reviewerID: String
    var sellerID: String
    var rating: Int // 1-5
    var comment: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case productID
        case reviewerID
        case sellerID
        case rating
        case comment
        case timestamp
    }
}