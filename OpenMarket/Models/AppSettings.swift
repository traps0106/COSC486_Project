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
        
        var exchangeRate: Double {
            switch self {
            case .BHD: return 1.0
            case .USD: return 2.65
            case .GBP: return 1.96
            case .EUR: return 2.26
            }
        }
    }
    
    func convertPrice(_ priceInBHD: Double) -> Double {
        return priceInBHD * currency.exchangeRate
    }
    
    func formatPrice(_ priceInBHD: Double) -> String {
        let convertedPrice = convertPrice(priceInBHD)
        return "\(currency.symbol) \(String(format: "%.2f", convertedPrice))"
    }
}