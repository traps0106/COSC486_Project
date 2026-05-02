import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Currency", selection: $settings.currency) {
                        ForEach(AppSettings.Currency.allCases, id: \.self) { currency in
                            HStack {
                                Text(currency.name)
                                Spacer()
                                Text(currency.symbol)
                                    .foregroundColor(.secondary)
                            }
                            .tag(currency)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Currency")
                } footer: {
                    HStack {
                        Text("Preview:")
                        Spacer()
                        Text(settings.formatPrice(100.0))
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    Picker("Appearance", selection: $themeManager.selectedTheme) {
                        ForEach(ThemeManager.Theme.allCases, id: \.self) { theme in
                            HStack {
                                Text(theme.rawValue)
                                Spacer()
                                Image(systemName: themeIcon(for: theme))
                                    .foregroundColor(.secondary)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Theme")
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Platform")
                        Spacer()
                        Text("iOS 17+")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    func themeIcon(for theme: ThemeManager.Theme) -> String {
        switch theme {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }
}