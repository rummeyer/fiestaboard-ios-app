import Foundation
import Observation

/// A message as the app keeps it: what was on the board, and the text it came from if any.
struct SavedMessage: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var characters: [[Int]]
    /// The text it was written as; none for one only seen on the board.
    var text: String?
    /// Who put it there: "You" from this app, "FiestaBoard" for what the board showed.
    var sender: String
    /// The board it was on; none for one kept before there were several.
    var boardID: String?
    var boardName: String
    var date: Date
    /// Whether it was a favorite, when favorites were part of the history: read once, to carry them over.
    var favorite = false

    /// The text to start a new message from: as written, or read back off the board.
    var editableText: String {
        text ?? characters.map { row in
            row.map { code -> String in
                if let name = Layout.colours.first(where: { $0.value == code && $0.key != "purple" })?.key {
                    return "{\(name)}"
                }
                if case let .character(letter) = Flap.of(code, heart: false) {
                    return letter.isEmpty ? " " : letter
                }
                return " "
            }.joined().trimmingCharacters(in: .whitespaces)
        }.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }
}

/// A message being written and kept for later.
struct Draft: Codable, Identifiable, Hashable, Sendable {
    var id = UUID()
    var text: String
    var date: Date
}

/// History, favorites and drafts, kept on this iPhone: FiestaBoard keeps none
/// of them. History is per board — what was sent to it from the app and what
/// it showed while the app was open, newest first. Favorites and drafts are
/// the same whichever board is chosen, and go to any.
@MainActor @Observable
final class Library {
    private static let limit = 300

    /// Every board's history, newest first.
    private(set) var messages: [SavedMessage] = []
    private(set) var favorites: [SavedMessage] = []
    private(set) var drafts: [Draft] = []

    private let url: URL
    private let favoritesURL: URL
    private let draftsURL: URL

    init() {
        let folder = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        // The sample screenshots' own files, started afresh each time.
        let prefix = Demo.on ? "sample-" : ""
        url = folder.appending(path: prefix + "messages.json")
        favoritesURL = folder.appending(path: prefix + "favorites.json")
        draftsURL = folder.appending(path: prefix + "drafts.json")
        if Demo.on {
            for file in [url, favoritesURL, draftsURL] {
                try? FileManager.default.removeItem(at: file)
            }
        }
        messages = Self.load(url) ?? []
        // Favorites were marked in the history once: carried over the first time.
        favorites = Self.load(favoritesURL) ?? messages.filter(\.favorite)
        drafts = Self.load(draftsURL) ?? []
    }

    /// One board's history. One kept before there were several is a FiestaBoard board's, any of them.
    func history(for board: String) -> [SavedMessage] {
        messages.filter { Self.belongs($0, to: board) }
    }

    func senders(for board: String) -> [String] {
        Array(Set(history(for: board).map(\.sender))).sorted()
    }

    /// The newest message in a board's history that is this content, if one is kept.
    func latest(_ characters: [[Int]], on board: String) -> SavedMessage? {
        history(for: board).first { $0.characters == characters }
    }

    /// A message sent from the app: at the top of that board's history.
    func sent(_ characters: [[Int]], text: String, board: String, boardName: String) {
        add(SavedMessage(characters: characters, text: text, sender: "You", boardID: board, boardName: boardName, date: .now))
    }

    /// What a board shows now, seen by the app: kept unless it is the newest one there already.
    func seen(_ characters: [[Int]], board: String, boardName: String) {
        guard characters.contains(where: { $0.contains { $0 != 0 } }), history(for: board).first?.characters != characters else {
            return
        }
        add(SavedMessage(characters: characters, sender: "FiestaBoard", boardID: board, boardName: boardName, date: .now))
    }

    private func add(_ message: SavedMessage) {
        messages.removeAll { $0.characters == message.characters && Self.belongs($0, to: message.boardID ?? "") }
        messages.insert(message, at: 0)
        messages = Array(messages.prefix(Self.limit))
        Self.write(messages, to: url)
    }

    func isFavorite(_ characters: [[Int]]) -> Bool {
        favorites.contains { $0.characters == characters }
    }

    /// Keeps a message as a favorite, or no longer.
    func toggleFavorite(_ message: SavedMessage) {
        if isFavorite(message.characters) {
            favorites.removeAll { $0.characters == message.characters }
        } else {
            var favorite = message
            favorite.id = UUID()
            favorite.favorite = true
            favorites.insert(favorite, at: 0)
        }
        Self.write(favorites, to: favoritesURL)
    }

    /// The same for what a board shows: as the history has it, or as it is.
    func toggleFavorite(_ characters: [[Int]], board: String, boardName: String) {
        toggleFavorite(latest(characters, on: board)
            ?? SavedMessage(characters: characters, sender: "FiestaBoard", boardID: board, boardName: boardName, date: .now))
    }

    /// Out of a board's history; a favorite of it stays.
    func delete(_ message: SavedMessage) {
        messages.removeAll { $0.id == message.id }
        Self.write(messages, to: url)
    }

    func saveDraft(_ text: String, replacing id: Draft.ID? = nil) {
        drafts.removeAll { $0.id == id }
        drafts.insert(Draft(text: text, date: .now), at: 0)
        Self.write(drafts, to: draftsURL)
    }

    func deleteDraft(_ id: Draft.ID) {
        drafts.removeAll { $0.id == id }
        Self.write(drafts, to: draftsURL)
    }

    private static func belongs(_ message: SavedMessage, to board: String) -> Bool {
        message.boardID == board || message.boardID == nil && board != VirtualBoard.id
    }

    private static func load<T: Decodable>(_ url: URL) -> T? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? Data(contentsOf: url)).flatMap { try? decoder.decode(T.self, from: $0) }
    }

    private static func write<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(value) {
            try? data.write(to: url, options: [.atomic, .completeFileProtection])
        }
    }
}
