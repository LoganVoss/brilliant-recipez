import SwiftUI
@main
struct RecipeSnapApp: App {
    @StateObject private var bookmarkManager = BookmarkManager()
    @StateObject private var purchaseManager = PurchaseManager()
    @Environment(\.scenePhase) private var scenePhase

    init() {
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(bookmarkManager)
                .environmentObject(purchaseManager)
                .background(Color.white.edgesIgnoringSafeArea(.all))
                .onAppear {
                    print("ContentView appeared")
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                    }
                }
        }
    }
}
