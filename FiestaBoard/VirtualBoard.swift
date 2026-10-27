import Foundation

/// What the app asks of a board: FiestaBoard's API, or the board simulated in demo mode.
protocol BoardService: Sendable {
    func boards() async throws -> [BoardSummary]
    func board(_ id: String) async throws -> BoardDetail
    func send(_ text: String, to board: String) async throws -> MessageResponse
    func send(characters: [[Int]], to board: String) async throws -> MessageResponse
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
        [BoardSummary(id: Self.id, name: name, rows: Self.rows, cols: Self.cols, isPrimary: false, paused: false)]
    }

    func board(_ id: String) async throws -> BoardDetail {
        BoardDetail(
            id: Self.id, name: name, deviceType: "note", rows: Self.rows, cols: Self.cols, paused: false,
            characters: characters, text: nil, resolvedPageId: nil, source: "manual", overrideExpiresAt: nil
        )
    }

    func send(_ text: String, to board: String) async throws -> MessageResponse {
        try await show(Layout.grid(text, rows: Self.rows, cols: Self.cols).grid)
    }

    func send(characters: [[Int]], to board: String) async throws -> MessageResponse {
        try await show(characters)
    }

    /// Shows a message, as FiestaBoard says it did: written, or the same as already there.
    private func show(_ grid: [[Int]]) async throws -> MessageResponse {
        guard grid != characters else {
            return MessageResponse(sent: false, characters: grid, reason: String(localized: "The board already shows this."), held: nil)
        }
        try await Task.sleep(for: .milliseconds(700))
        characters = grid
        UserDefaults.standard.set(grid, forKey: Self.key)
        return MessageResponse(sent: true, characters: grid, reason: nil, held: nil)
    }

    /// Puts content on the board without a message, as for the sample screenshots.
    func set(_ grid: [[Int]]) {
        characters = grid
    }
}
