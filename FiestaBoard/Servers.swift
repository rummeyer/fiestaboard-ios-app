import Foundation
import OSLog

private let log = Logger(subsystem: "de.rummeyer.fiestaboard", category: "servers")

/// FiestaBoard at two addresses: on the home network, and from anywhere. A
/// router seldom lets a phone at home reach its own public address, and the
/// home address is out of reach away from home — so a request goes to the
/// address that answered last, and to the other when that one cannot be
/// reached at all. An answer, even a refusal, counts as reached.
struct FiestaBoardServers: BoardService {
    /// Local first, then remote; one of them at least.
    let servers: [FiestaBoardAPI]

    /// From what was typed in; an address left empty is not there. Nil when neither is.
    init?(local: String, remote: String, token: String) throws {
        servers = try [local, remote]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { try FiestaBoardAPI(address: $0, token: token) }
        if servers.isEmpty {
            return nil
        }
    }

    func boards() async throws -> [BoardSummary] {
        log.info("Servers: \(servers.map { $0.base.host(percentEncoded: false) ?? "?" }.joined(separator: " and "))")
        return try await reach(again: true) { try await $0.boards() }
    }

    func board(_ id: String) async throws -> BoardDetail {
        try await reach(again: true) { try await $0.board(id) }
    }

    func send(_ text: String, to board: String, minutes: Int?) async throws -> MessageResponse {
        try await reach(again: false) { try await $0.send(text, to: board, minutes: minutes) }
    }

    func send(characters: [[Int]], to board: String, minutes: Int?) async throws -> MessageResponse {
        try await reach(again: false) { try await $0.send(characters: characters, to: board, minutes: minutes) }
    }

    func clear(_ board: String) async throws -> MessageResponse {
        try await reach(again: false) { try await $0.clear(board) }
    }

    /// Tries the servers, the one that answered last first. `again`: whether the request may go
    /// to the other after one that may have arrived — a read may, a message is not sent twice.
    private func reach<T: Sendable>(again: Bool, _ request: @Sendable (FiestaBoardAPI) async throws -> T) async throws -> T {
        let ordered = await LastAnswered.shared.order(servers)
        var failure: Error = APIError.badAddress
        for (index, server) in ordered.enumerated() {
            let last = index == ordered.count - 1
            // Not the last to try: soon given up, so that the other is not waited for long.
            var attempt = server
            attempt.timeout = last ? 20 : 6
            let host = server.base.host(percentEncoded: false) ?? "?"
            do {
                let answer = try await request(attempt)
                if index > 0 || servers.count == 1 {
                    log.info("Servers: \(host) answered")
                }
                await LastAnswered.shared.answered(server)
                return answer
            } catch let error as URLError where Self.unreached(error, again: again) && !last {
                log.info("Servers: \(host) not reached (\(error.code.rawValue)), trying the other")
                failure = error
            } catch {
                log.error("Servers: \(host) failed, \(error.localizedDescription)")
                throw error
            }
        }
        throw failure
    }

    /// The server was not reached: no connection, no name, no secure channel; and with
    /// `again`, also one that went silent, which a read can be asked of the other again.
    private static func unreached(_ error: URLError, again: Bool) -> Bool {
        switch error.code {
        case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .notConnectedToInternet,
             .secureConnectionFailed, .serverCertificateUntrusted, .serverCertificateHasBadDate,
             .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot, .internationalRoamingOff:
            true
        case .timedOut, .networkConnectionLost:
            again
        default:
            false
        }
    }
}

/// Which address answered last, for as long as the app runs.
private actor LastAnswered {
    static let shared = LastAnswered()

    private var base: URL?

    func order(_ servers: [FiestaBoardAPI]) -> [FiestaBoardAPI] {
        guard let base, let index = servers.firstIndex(where: { $0.base == base }) else {
            return servers
        }
        var ordered = servers
        ordered.insert(ordered.remove(at: index), at: 0)
        return ordered
    }

    func answered(_ server: FiestaBoardAPI) {
        base = server.base
    }
}
