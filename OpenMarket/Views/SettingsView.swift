import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
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
                        Text("\(settings.currency.symbol) 100.00")
                            .fontWeight(.semibold)
                    }
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
}