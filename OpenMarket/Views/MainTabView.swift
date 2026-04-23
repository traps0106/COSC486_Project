import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ProductListView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
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