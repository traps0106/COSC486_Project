import SwiftUI

struct AppTheme {
    // Primary Colors
    static let primaryBlue = Color.blue
    static let primaryGreen = Color.green
    static let primaryOrange = Color.orange
    static let primaryRed = Color.red
    
    // Background Colors
    static let backgroundColor = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let cardBackground = Color(.systemGray6)
    
    // Text Colors
    static let primaryText = Color.primary
    static let secondaryText = Color.secondary
    
    // Fonts
    static let largeTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title.weight(.bold)
    static let title2 = Font.title2.weight(.bold)
    static let headline = Font.headline
    static let body = Font.body
    static let caption = Font.caption
    
    // Spacing
    static let smallPadding: CGFloat = 8
    static let mediumPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
    
    // Corner Radius
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    
    // Shadows
    static let cardShadow = Color.black.opacity(0.1)
    static let shadowRadius: CGFloat = 4
}