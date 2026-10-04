import SwiftUI

@main
struct AuraLinkWatchApp: App {
    @StateObject private var model = WatchModel()
    var body: some Scene {
        WindowGroup { NavigationStack { FacingListView() }.environmentObject(model) }
    }
}
