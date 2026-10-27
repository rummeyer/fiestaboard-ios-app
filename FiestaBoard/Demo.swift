import Foundation

/// Sample content for looking at the app without a FiestaBoard, in a debug
/// build started with `-demo`; `-demoCompose` opens the compose screen too.
enum Demo {
    #if DEBUG
    static let on = ProcessInfo.processInfo.arguments.contains("-demo")
    static let compose = ProcessInfo.processInfo.arguments.contains("-demoCompose")
    #else
    static let on = false
    static let compose = false
    #endif

    static let shape = BoardShape.note

    static func grid(_ text: String) -> [[Int]] {
        Layout.grid(text, rows: shape.rows, cols: shape.cols).grid
    }

    static var board: BoardDetail {
        BoardDetail(
            id: "demo", name: "Vestaboard Note", deviceType: "note", rows: 3, cols: 15, paused: false,
            characters: grid("{yellow}{blue} {red}{red}{orange}{yellow}{blue} {red}{red}{orange}{yellow}\n KAFFEE IST\n   FERTIG {red}"),
            text: nil, resolvedPageId: nil, source: "manual", overrideExpiresAt: nil
        )
    }

    @MainActor
    static func fill(_ library: Library) {
        guard library.messages.isEmpty else {
            return
        }
        library.seen(grid("ES IST VIERTEL\nNACH VIER"), boardName: "Vestaboard Note")
        library.sent(grid("{orange}{orange} GUTEN {orange}{orange}\n   MORGEN!"), text: "{orange}{orange} GUTEN {orange}{orange}\n   MORGEN!", boardName: "Vestaboard Note")
        library.toggleFavorite(grid("{orange}{orange} GUTEN {orange}{orange}\n   MORGEN!"), boardName: "Vestaboard Note")
        library.sent(board.characters!, text: "KAFFEE IST FERTIG", boardName: "Vestaboard Note")
    }
}
