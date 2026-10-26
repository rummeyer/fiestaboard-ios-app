import Foundation

/// A board as `GET /api/v1/boards` lists it.
struct BoardSummary: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let rows: Int
    let cols: Int
    let isPrimary: Bool
    let paused: Bool
}

private struct BoardList: Decodable {
    let boards: [BoardSummary]
}

/// One board and what is on it now, from `GET /api/v1/boards/{board}`.
struct BoardDetail: Decodable, Sendable {
    let id: String
    let name: String
    let deviceType: String
    let rows: Int
    let cols: Int
    let paused: Bool
    /// The flap codes on the board, row by row; nothing until something was sent.
    let characters: [[Int]]?
    let text: String?
    let resolvedPageId: String?
    /// Where the page shown came from: "manual", "schedule" or "none".
    let source: String
    /// When a timed message reverts, ISO 8601.
    let overrideExpiresAt: String?
}

/// What a write did, from `POST /api/v1/boards/{board}/message`.
struct MessageResponse: Decodable, Sendable {
    /// True only when the board was written to.
    let sent: Bool
    let reason: String?
    let held: Bool?
}

enum APIError: LocalizedError {
    case badAddress
    case unauthorized
    case server(status: Int, detail: String)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .badAddress:
            "The server address is not an https:// address."
        case .unauthorized:
            "The token was not accepted."
        case let .server(status, detail):
            detail.isEmpty ? "The server answered \(status)." : detail
        case .unreadable:
            "The server's answer could not be read."
        }
    }
}

/// FiestaBoard's public API, version 1: <server>/api/v1/…, with a bearer token.
struct FiestaBoardAPI: Sendable {
    let base: URL
    let token: String

    /// From what was typed in: an https address, with or without a trailing /api.
    init(address: String, token: String) throws {
        var text = address.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix("/") {
            text.removeLast()
        }
        if text.hasSuffix("/api") {
            text.removeLast(4)
        }
        guard let url = URL(string: text), url.scheme?.lowercased() == "https", url.host() != nil else {
            throw APIError.badAddress
        }
        base = url.appending(path: "api/v1")
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func boards() async throws -> [BoardSummary] {
        let list: BoardList = try await call("GET", "boards")
        return list.boards
    }

    func board(_ id: String) async throws -> BoardDetail {
        try await call("GET", "boards/\(id)")
    }

    func send(_ text: String, to board: String) async throws -> MessageResponse {
        try await call("POST", "boards/\(board)/message", body: ["text": text])
    }

    private func call<T: Decodable>(_ method: String, _ path: String, body: [String: String]? = nil) async throws -> T {
        var request = URLRequest(url: base.appending(path: path))
        request.httpMethod = method
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let status = (response as? HTTPURLResponse)?.statusCode else {
            throw APIError.unreadable
        }
        if status == 401 || status == 403 {
            throw APIError.unauthorized
        }
        guard (200..<300).contains(status) else {
            throw APIError.server(status: status, detail: Self.detail(of: data))
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.unreadable
        }
    }

    /// An error's `detail`: text, or for a validation error the first message in it.
    private static func detail(of data: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ""
        }
        if let text = object["detail"] as? String {
            return text
        }
        if let first = (object["detail"] as? [[String: Any]])?.first, let text = first["msg"] as? String {
            return text
        }
        if let text = (object["detail"] as? [String: Any])?["message"] as? String {
            return text
        }
        return ""
    }
}
