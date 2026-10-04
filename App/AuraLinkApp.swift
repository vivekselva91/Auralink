import SwiftUI

@main
struct AuraLinkApp: App {
    @StateObject private var coordinator = InteractionCoordinator()
    var body: some Scene {
        WindowGroup { NavigationStack { ContentView() }.environmentObject(coordinator) }
    }
}
