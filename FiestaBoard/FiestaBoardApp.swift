import SwiftUI

@main
struct FiestaBoardApp: App {
    @State private var settings = Settings()
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            Group {
                if settings.isComplete {
                    HomeView()
                } else {
                    NavigationStack {
                        SettingsView(isFirstRun: true)
                    }
                }
            }
            .environment(settings)
            .environment(library)
            .preferredColorScheme(.dark)
        }
    }
}
