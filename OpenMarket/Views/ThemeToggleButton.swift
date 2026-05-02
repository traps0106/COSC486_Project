import SwiftUI

struct ThemeToggleButton: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Button(action: cycleTheme) {
            Image(systemName: currentIcon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 32, height: 32)
                .background(Color(.systemGray5))
                .clipShape(Circle())
        }
    }
    
    private var currentIcon: String {
        switch themeManager.selectedTheme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
    
    private func cycleTheme() {
        switch themeManager.selectedTheme {
        case .light:
            themeManager.selectedTheme = .dark
        case .dark:
            themeManager.selectedTheme = .system
        case .system:
            themeManager.selectedTheme = .light
        }
    }
}