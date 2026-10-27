import Foundation

/// Sample content for looking at the app without a FiestaBoard, in a debug
/// build started with `-demo`: `-demoCompose` opens the compose screen,
/// `-demoVisual` the same drawn tile by tile,
/// `-demoLive` the board large, `-demoSettings` the first start.
enum Demo {
    #if DEBUG
    private static let arguments = ProcessInfo.processInfo.arguments
    static let on = arguments.contains("-demo")
    static let compose = arguments.contains("-demoCompose")
    static let visual = arguments.contains("-demoVisual")
    static let live = arguments.contains("-demoLive")
    static let settings = arguments.contains("-demoSettings")
    #else
    static let on = false
    static let compose = false
    static let visual = false
    static let live = false
    static let settings = false
    #endif

    static let shape = BoardShape.note

    /// A message drawn in the visual editor: a word between two rainbows.
    static let drawn: [[Int]] = {
        let rainbow = [63, 64, 65, 66, 67, 68]
        let stripe = (0..<15).map { rainbow[$0 % rainbow.count] }
        return [stripe, Layout.tiles(of: "COFFEE IS READY"), stripe.reversed()]
    }()

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

/// A second board for the sample screenshots alone: an LED pixel clock, 3 × 13,
/// to show the board selector and how an LED panel is drawn.
actor SampleClock: BoardService {
    static let shared = SampleClock()
    static let id = "sample-clock"

    private var characters = Layout.grid("  ES IST\n HALB ZWEI\n{green}{green}{green}{green}{green}{green}{green}{green}{green}{green}{green}{green}{green}", rows: 3, cols: 13).grid

    func boards() async throws -> [BoardSummary] {
        [BoardSummary(id: Self.id, name: "Pixel Clock", rows: 3, cols: 13, isPrimary: false, paused: false)]
    }

    func board(_ id: String) async throws -> BoardDetail {
        BoardDetail(id: Self.id, name: "Pixel Clock", deviceType: "panel", rows: 3, cols: 13, paused: false,
                    characters: characters, text: nil, resolvedPageId: nil, source: "schedule", overrideExpiresAt: nil)
    }

    func send(_ text: String, to board: String, minutes: Int?) async throws -> MessageResponse {
        characters = Layout.grid(text, rows: 3, cols: 13).grid
        return MessageResponse(sent: true, characters: characters, reason: nil, held: nil)
    }

    func send(characters: [[Int]], to board: String, minutes: Int?) async throws -> MessageResponse {
        self.characters = characters
        return MessageResponse(sent: true, characters: characters, reason: nil, held: nil)
    }

    func clear(_ board: String) async throws -> MessageResponse {
        MessageResponse(sent: true, characters: characters, reason: nil, held: nil)
    }
}
