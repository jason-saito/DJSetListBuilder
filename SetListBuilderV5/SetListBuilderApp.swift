import SwiftUI
// added comment jan 8
@main
struct SetListBuilderApp: App {
    @StateObject private var soundCloudService = SoundCloudService()
    @StateObject private var setListService = SetListService()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(soundCloudService)
            .environmentObject(setListService)
        }
    }
} 
