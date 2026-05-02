import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var selectedTheme: Theme = .system
    
    static let shared = ThemeManager()
    
    private init() {}
    
    enum Theme: String, CaseIterable, Codable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
}