import Foundation
import Observation
import Security

/// Where FiestaBoard is and the token for it — its addresses in the defaults,
/// the token in the Keychain, as it opens everything the API can do — and
/// whether the demo board is there beside its boards, or instead of them.
@MainActor @Observable
final class Settings {
    /// The remote server's: once the only address, which may have been the local one.
    private static let addressKey = "serverAddress"
    private static let localKey = "localServerAddress"
    private static let tokenAccount = "apiToken"
    private static let demoKey = "demoBoard"
    private static let looksKey = "boardLooks"

    /// FiestaBoard from anywhere, over HTTPS.
    var address: String
    /// FiestaBoard on the home network: tried when the remote server cannot be reached.
    var localAddress: String
    var token: String
    /// The board simulated in the app, beside FiestaBoard's or alone.
    var demoBoard: Bool {
        didSet {
            UserDefaults.standard.set(demoBoard, forKey: Self.demoKey)
        }
    }

    /// How each board looks, as set in the app: FiestaBoard does not say. By board id.
    var looks: [String: BoardLook] {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(looks), forKey: Self.looksKey)
        }
    }

    /// A board's look: as set, else as its kind mostly is.
    func look(for board: String, deviceType: String?) -> BoardLook {
        looks[board] ?? BoardLook.usual(for: deviceType)
    }

    init() {
        // The demo shows none of the real address or token.
        address = Demo.on ? "" : UserDefaults.standard.string(forKey: Self.addressKey) ?? ""
        localAddress = Demo.on ? "" : UserDefaults.standard.string(forKey: Self.localKey) ?? ""
        token = Demo.on ? "" : Keychain.read(Self.tokenAccount) ?? ""
        // The sample screenshots are on the demo board alone, but their first start shows it off.
        demoBoard = Demo.on ? !Demo.settings : UserDefaults.standard.bool(forKey: Self.demoKey)
        looks = Demo.on ? [:] : UserDefaults.standard.data(forKey: Self.looksKey)
            .flatMap { try? JSONDecoder().decode([String: BoardLook].self, from: $0) } ?? [:]
        // The one address of before, at home: the local server's now.
        if localAddress.isEmpty, let host = (try? FiestaBoardAPI(address: address, token: ""))?.base.host(percentEncoded: false),
           FiestaBoardAPI.isLocal(host) {
            localAddress = address
            address = ""
            UserDefaults.standard.set(localAddress, forKey: Self.localKey)
            UserDefaults.standard.set(address, forKey: Self.addressKey)
        }
    }

    /// A FiestaBoard to talk to: an address that will do, and a token.
    var hasFiestaBoard: Bool {
        fiestaBoard != nil
    }

    var fiestaBoard: FiestaBoardServers? {
        token.isEmpty ? nil : (try? FiestaBoardServers(local: localAddress, remote: address, token: token)) ?? nil
    }

    /// Something to show: FiestaBoard's boards, the demo board, or both.
    var isComplete: Bool {
        !Demo.settings && (demoBoard || hasFiestaBoard)
    }

    /// Where a board's requests go: the demo board's to the app itself, every other to FiestaBoard.
    func service(for board: String) throws -> any BoardService {
        if board == VirtualBoard.id {
            return VirtualBoard.shared
        }
        if Demo.on && board == SampleClock.id {
            return SampleClock.shared
        }
        guard let fiestaBoard else {
            throw APIError.badAddress
        }
        return fiestaBoard
    }

    func save(local: String, remote: String, token: String) {
        localAddress = local.trimmingCharacters(in: .whitespacesAndNewlines)
        address = remote.trimmingCharacters(in: .whitespacesAndNewlines)
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(localAddress, forKey: Self.localKey)
        UserDefaults.standard.set(address, forKey: Self.addressKey)
        Keychain.write(self.token, for: Self.tokenAccount)
    }
}

/// What FiestaBoard knows of a board but does not tell through its API: the
/// colour of its flaps, and what its code 62 flap shows.
struct BoardLook: Codable, Equatable, Sendable {
    /// White flaps, on which white (69) and black (70) tiles show the other way round.
    var white: Bool
    /// Code 62 a heart; else a degree sign.
    var heart: Bool

    /// A Note white with a heart, a Flagship black with a degree sign, as they mostly are.
    static func usual(for deviceType: String?) -> BoardLook {
        let note = deviceType?.hasPrefix("note") ?? false
        return BoardLook(white: note, heart: note)
    }
}

private enum Keychain {
    private static let service = "de.rummeyer.fiestaboard"

    static func read(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    static func write(_ value: String, for account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        guard !value.isEmpty else {
            return
        }
        var item = query
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(item as CFDictionary, nil)
    }
}
