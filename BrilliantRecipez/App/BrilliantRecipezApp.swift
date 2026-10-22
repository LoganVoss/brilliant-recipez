import SwiftUI

@main
struct BrilliantRecipezApp: App {
    @StateObject private var model = AppModel()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(model).tint(Theme.tint)
        }
    }
}
