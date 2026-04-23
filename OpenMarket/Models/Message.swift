import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable {
    @DocumentID var id: String?
    var senderID: String
    var receiverID: String
    var text: String
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderID
        case receiverID
        case text
        case timestamp
    }
}