import Foundation
import FirebaseFirestore
import CoreLocation

struct Product: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var price: Double
    var category: String
    var imageURL: String?
    var sellerID: String
    var latitude: Double
    var longitude: Double
    var averageRating: Double
    var createdAt: Date
    var quantity: Int
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func distance(from userLocation: CLLocation) -> Double {
        let productLocation = CLLocation(latitude: latitude, longitude: longitude)
        return userLocation.distance(from: productLocation) / 1000 // in km
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case price
        case category
        case imageURL
        case sellerID
        case latitude
        case longitude
        case averageRating
        case createdAt
        case quantity
    }
}