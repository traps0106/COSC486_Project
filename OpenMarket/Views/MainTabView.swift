import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ProductListView()
                .tabItem {
                    Label("Market", systemImage: "cart.fill")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
            
            ConversationsListView()
                .tabItem {
                    Label("Messages", systemImage: "message.fill")
                }
            
            AddProductView()
                .tabItem {
                    Label("Sell", systemImage: "plus.circle.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}