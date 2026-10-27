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
    var boardName: String
    var date: Date
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
/// of them. History is what was sent from the app and what the board showed
/// while the app was open, newest first; a favorite stays when it falls out of
/// the history.
@MainActor @Observable
final class Library {
    private static let limit = 300

    private(set) var messages: [SavedMessage] = []
    private(set) var drafts: [Draft] = []

    private let url: URL
    private let draftsURL: URL

    init() {
        let folder = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        url = folder.appending(path: "messages.json")
        draftsURL = folder.appending(path: "drafts.json")
        messages = Self.load(url) ?? []
        drafts = Self.load(draftsURL) ?? []
    }

    var favorites: [SavedMessage] {
        messages.filter(\.favorite)
    }

    var senders: [String] {
        Array(Set(messages.map(\.sender))).sorted()
    }

    /// The newest message that is this board content, if one is kept.
    func latest(_ characters: [[Int]]) -> SavedMessage? {
        messages.first { $0.characters == characters }
    }

    /// A message sent from the app: at the top of the history.
    func sent(_ characters: [[Int]], text: String, boardName: String) {
        add(SavedMessage(characters: characters, text: text, sender: "You", boardName: boardName, date: .now))
    }

    /// What the board shows now, seen by the app: kept unless it is the newest one already.
    func seen(_ characters: [[Int]], boardName: String) {
        guard characters.contains(where: { $0.contains { $0 != 0 } }), messages.first?.characters != characters else {
            return
        }
        add(SavedMessage(characters: characters, sender: "FiestaBoard", boardName: boardName, date: .now))
    }

    private func add(_ message: SavedMessage) {
        var message = message
        message.favorite = messages.contains { $0.favorite && $0.characters == message.characters }
        messages.removeAll { $0.characters == message.characters && !$0.favorite }
        messages.removeAll { $0.characters == message.characters && message.favorite }
        messages.insert(message, at: 0)
        var kept = 0
        messages = messages.filter { each in
            if each.favorite {
                return true
            }
            kept += 1
            return kept <= Self.limit
        }
        save()
    }

    func isFavorite(_ characters: [[Int]]) -> Bool {
        messages.contains { $0.favorite && $0.characters == characters }
    }

    /// Marks a message, or board content not kept yet, as a favorite, or no longer.
    func toggleFavorite(_ characters: [[Int]], boardName: String) {
        if let index = messages.firstIndex(where: { $0.characters == characters }) {
            let favorite = !messages[index].favorite
            for i in messages.indices where messages[i].characters == characters {
                messages[i].favorite = favorite
            }
        } else {
            messages.insert(SavedMessage(characters: characters, sender: "FiestaBoard", boardName: boardName, date: .now, favorite: true), at: 0)
        }
        save()
    }

    func delete(_ message: SavedMessage) {
        messages.removeAll { $0.id == message.id }
        save()
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

    private func save() {
        Self.write(messages, to: url)
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
