import Foundation

/// Sample content for looking at the app without a FiestaBoard, in a debug
/// build started with `-demo`: `-demoCompose` opens the compose screen,
/// `-demoLive` the board large, `-demoSettings` the first start.
enum Demo {
    #if DEBUG
    private static let arguments = ProcessInfo.processInfo.arguments
    static let on = arguments.contains("-demo")
    static let compose = arguments.contains("-demoCompose")
    static let live = arguments.contains("-demoLive")
    static let settings = arguments.contains("-demoSettings")
    #else
    static let on = false
    static let compose = false
    static let live = false
    static let settings = false
    #endif

    static let shape = BoardShape.note

    static func grid(_ text: String) -> [[Int]] {
        Layout.grid(text, rows: shape.rows, cols: shape.cols).grid
    }

    static let sample = grid("{yellow}{blue} {red}{red}{orange}{yellow}{blue} {red}{red}{orange}{yellow}\n KAFFEE IST\n   FERTIG {red}")

    /// The sample screenshots' content: on the simulated board and in its history.
    @MainActor
    static func fill(_ library: Library) async {
        guard library.messages.isEmpty else {
            return
        }
        await VirtualBoard.shared.set(sample)
        let board = VirtualBoard.id
        let name = String(localized: "Demo Board")
        library.seen(grid("ES IST VIERTEL\nNACH VIER"), board: board, boardName: name)
        library.seen(grid("WOHNEN  22°C 48%\nSCHLAF  21°C 51%\nBALKON   9°C 86%"), board: board, boardName: name)
        library.saveDraft("Geburtstag! {red}{orange}{yellow}")
        let morning = "{orange}{orange} GUTEN {orange}{orange}\n   MORGEN!"
        library.sent(grid(morning), text: morning, board: board, boardName: name)
        library.toggleFavorite(grid(morning), board: board, boardName: name)
        library.sent(sample, text: "KAFFEE IST FERTIG", board: board, boardName: name)
    }
}
