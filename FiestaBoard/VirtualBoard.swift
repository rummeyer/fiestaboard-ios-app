import Foundation

/// What the app asks of a board: FiestaBoard's API, or the board simulated in demo mode.
protocol BoardService: Sendable {
    func boards() async throws -> [BoardSummary]
    func board(_ id: String) async throws -> BoardDetail
    func send(_ text: String, to board: String, minutes: Int?) async throws -> MessageResponse
    func send(characters: [[Int]], to board: String, minutes: Int?) async throws -> MessageResponse
    func clear(_ board: String) async throws -> MessageResponse
}

extension FiestaBoardAPI: BoardService {}

/// The demo board, simulated in the app, beside FiestaBoard's boards or alone:
/// a white 3 × 15 board that takes a message as FiestaBoard does — laid out
/// the same way, a moment for the flaps to turn — and keeps what it shows
/// across launches.
actor VirtualBoard: BoardService {
    static let shared = VirtualBoard()

    static let id = "demo"
    private static let rows = 3
    private static let cols = 15
    private static let key = "virtualBoard"

    private var characters: [[Int]]
    /// A timed message's end, and what the board showed before it, to go back to.
    private var until: Date?
    private var before: [[Int]]?

    init() {
        if let saved = UserDefaults.standard.array(forKey: Self.key) as? [[Int]], saved.count == Self.rows {
            characters = saved
        } else {
            characters = Layout.grid(String(localized: "HELLO FROM\nFIESTABOARD\n{red}{orange}{yellow}{green}{blue}{violet}"), rows: Self.rows, cols: Self.cols).grid
        }
    }

    private var name: String {
        String(localized: "Demo Board")
    }

    func boards() async throws -> [BoardSummary] {
        [BoardSummary(id: Self.id, name: name, rows: Self.rows, cols: Self.cols, isPrimary: false, paused: false, deviceType: "note")]
    }

    func board(_ id: String) async throws -> BoardDetail {
        expire()
        return BoardDetail(
            id: Self.id, name: name, deviceType: "note", rows: Self.rows, cols: Self.cols, paused: false,
            characters: characters, text: nil, resolvedPageId: nil, source: "manual",
            overrideExpiresAt: until.map { $0.ISO8601Format() }
        )
    }

    func send(_ text: String, to board: String, minutes: Int?) async throws -> MessageResponse {
        try await show(Layout.grid(text, rows: Self.rows, cols: Self.cols).grid, minutes: minutes)
    }

    func send(characters: [[Int]], to board: String, minutes: Int?) async throws -> MessageResponse {
        try await show(characters, minutes: minutes)
    }

    /// Back to what the board showed before a timed message, as FiestaBoard goes back to its schedule.
    func clear(_ board: String) async throws -> MessageResponse {
        if let before {
            try await Task.sleep(for: .milliseconds(700))
            put(before)
        }
        until = nil
        before = nil
        return MessageResponse(sent: true, characters: characters, reason: nil, held: nil)
    }

    /// Shows a message, as FiestaBoard says it did: written, or the same as already there. Timed,
    /// it gives way to what was there before once its time is up.
    private func show(_ grid: [[Int]], minutes: Int?) async throws -> MessageResponse {
        expire()
        guard grid != characters else {
            return MessageResponse(sent: false, characters: grid, reason: String(localized: "The board already shows this."), held: nil)
        }
        try await Task.sleep(for: .milliseconds(700))
        if let minutes {
            before = before ?? characters
            until = .now.addingTimeInterval(TimeInterval(minutes * 60))
        } else {
            before = nil
            until = nil
        }
        put(grid)
        return MessageResponse(sent: true, characters: grid, reason: nil, held: nil, expiresAt: until.map { $0.ISO8601Format() })
    }

    private func expire() {
        if let until, until <= .now, let before {
            put(before)
            self.until = nil
            self.before = nil
        }
    }

    private func put(_ grid: [[Int]]) {
        characters = grid
        UserDefaults.standard.set(grid, forKey: Self.key)
    }

    /// Puts content on the board without a message, as for the sample screenshots.
    func set(_ grid: [[Int]]) {
        characters = grid
    }
}
