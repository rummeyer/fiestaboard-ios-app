import Foundation

/// A board as `GET /api/v1/boards` lists it.
struct BoardSummary: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let rows: Int
    let cols: Int
    let isPrimary: Bool
    let paused: Bool
    /// "flagship", "note", "note_array" or "panel"; none for one from before it was read.
    var deviceType: String?
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
    /// What the message became on the board, sent or not.
    let characters: [[Int]]
    let reason: String?
    let held: Bool?
    /// When a timed message gives way to the schedule again, ISO 8601.
    var expiresAt: String? = nil
}

enum APIError: LocalizedError {
    case badAddress
    case unauthorized
    case server(status: Int, detail: String)
    case unreadable

    var errorDescription: String? {
        switch self {
        case .badAddress:
            String(localized: "Use an https:// address, or http:// for one on your network or VPN: 10.x, 172.16–31.x, 192.168.x, 100.64–127.x or a .local name.")
        case .unauthorized:
            String(localized: "The token was not accepted.")
        case let .server(status, detail):
            detail.isEmpty ? String(localized: "The server answered \(status).") : detail
        case .unreadable:
            String(localized: "The server's answer could not be read.")
        }
    }
}

/// FiestaBoard's public API, version 1: <server>/api/v1/…, with a bearer token.
struct FiestaBoardAPI: Sendable {
    let base: URL
    let token: String

    /// From what was typed in, with or without a trailing /api: https anywhere,
    /// http only to an address on the home network or reached through a VPN, as
    /// the token goes with every request. Without a scheme, http for such an
    /// address, else https.
    init(address: String, token: String) throws {
        var text = address.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.hasSuffix("/") {
            text.removeLast()
        }
        if text.hasSuffix("/api") {
            text.removeLast(4)
        }
        if !text.contains("://"), let host = URL(string: "http://\(text)")?.host(percentEncoded: false) {
            text = (Self.isLocal(host) ? "http://" : "https://") + text
        }
        guard let url = URL(string: text), let host = url.host(percentEncoded: false) else {
            throw APIError.badAddress
        }
        switch url.scheme?.lowercased() {
        case "https":
            break
        case "http" where Self.isLocal(host):
            break
        default:
            throw APIError.badAddress
        }
        base = url.appending(path: "api/v1")
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Whether a host can only be reached at home or through a VPN: a private
    /// IPv4 or IPv6 address, the range Tailscale and other carrier-grade NAT
    /// use, a .local name, or a name without a dot.
    static func isLocal(_ host: String) -> Bool {
        let name = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        if name.hasSuffix(".local") || name == "localhost" {
            return true
        }
        let parts = name.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count == 4, case let octets = parts.compactMap({ UInt8($0) }), octets.count == 4 {
            switch (octets[0], octets[1]) {
            case (10, _), (127, _), (192, 168), (169, 254):
                return true
            case (172, 16...31), (100, 64...127):
                return true
            default:
                return false
            }
        }
        if name.contains(":") {
            // Unique local (fc00::/7), link-local (fe80::/10) and loopback.
            return name.hasPrefix("fc") || name.hasPrefix("fd") || name.hasPrefix("fe8") || name.hasPrefix("fe9")
                || name.hasPrefix("fea") || name.hasPrefix("feb") || name == "::1"
        }
        return !name.contains(".")
    }

    func boards() async throws -> [BoardSummary] {
        let list: BoardList = try await call("GET", "boards")
        return list.boards
    }

    func board(_ id: String) async throws -> BoardDetail {
        try await call("GET", "boards/\(id)")
    }

    /// A message for `minutes`, held against the schedule and then gone again; none, until replaced.
    func send(_ text: String, to board: String, minutes: Int?) async throws -> MessageResponse {
        try await call("POST", "boards/\(board)/message", body: Body(text: text, minutes: minutes))
    }

    /// A message as it was on a board, flap for flap: for one of the same size.
    func send(characters: [[Int]], to board: String, minutes: Int?) async throws -> MessageResponse {
        try await call("POST", "boards/\(board)/message", body: Body(characters: characters, minutes: minutes))
    }

    /// The board back to its schedule: a timed message ended before its time.
    func clear(_ board: String) async throws -> MessageResponse {
        try await call("DELETE", "boards/\(board)/message")
    }

    /// What a message is sent as: one of text or flaps, and for how long.
    private struct Body: Encodable {
        var text: String?
        var characters: [[Int]]?
        var minutes: Int?

        private enum Keys: String, CodingKey {
            case text, characters
            case minutes = "duration_minutes"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Keys.self)
            try container.encodeIfPresent(text, forKey: .text)
            try container.encodeIfPresent(characters, forKey: .characters)
            try container.encodeIfPresent(minutes, forKey: .minutes)
        }
    }

    private func call<T: Decodable>(_ method: String, _ path: String, body: Body? = nil) async throws -> T {
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
