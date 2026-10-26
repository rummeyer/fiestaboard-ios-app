import SwiftUI

@main
struct FiestaBoardApp: App {
    @State private var settings = Settings()

    var body: some Scene {
        WindowGroup {
            Group {
                if settings.isComplete {
                    BoardScreen()
                } else {
                    NavigationStack {
                        SettingsView(isFirstRun: true)
                    }
                }
            }
            .environment(settings)
        }
    }
}
