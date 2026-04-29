import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var currency: Currency = .BHD
    
    static let shared = AppSettings()
    
    private init() {}
    
    enum Currency: String, CaseIterable, Codable {
        case USD = "$"
        case BHD = "BD"
        case GBP = "£"
        case EUR = "€"
        
        var symbol: String {
            return self.rawValue
        }
        
        var name: String {
            switch self {
            case .USD: return "US Dollar"
            case .BHD: return "Bahraini Dinar"
            case .GBP: return "British Pound"
            case .EUR: return "Euro"
            }
        }
    }
}