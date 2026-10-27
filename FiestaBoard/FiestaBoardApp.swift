import SwiftUI

@main
struct FiestaBoardApp: App {
    @State private var settings = Settings()
    @State private var library = Library()
    /// From the start, so that a tip left unfinished is finished.
    @State private var tips = TipJar()

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
            .environment(tips)
            .font(Style.font(.body))
            .tint(Style.primary)
        }
    }
}
