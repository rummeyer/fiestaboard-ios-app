import Foundation
import Observation
import Security

/// Where FiestaBoard is and the token for it — the address in the defaults,
/// the token in the Keychain, as it opens everything the API can do — and
/// whether the demo board is there beside its boards, or instead of them.
@MainActor @Observable
final class Settings {
    private static let addressKey = "serverAddress"
    private static let tokenAccount = "apiToken"
    private static let demoKey = "demoBoard"

    var address: String
    var token: String
    /// The board simulated in the app, beside FiestaBoard's or alone.
    var demoBoard: Bool {
        didSet {
            UserDefaults.standard.set(demoBoard, forKey: Self.demoKey)
        }
    }

    init() {
        // The demo shows none of the real address or token.
        address = Demo.on ? "" : UserDefaults.standard.string(forKey: Self.addressKey) ?? ""
        token = Demo.on ? "" : Keychain.read(Self.tokenAccount) ?? ""
        // The sample screenshots are on the demo board alone, but their first start shows it off.
        demoBoard = Demo.on ? !Demo.settings : UserDefaults.standard.bool(forKey: Self.demoKey)
    }

    /// A FiestaBoard to talk to: an address that will do, and a token.
    var hasFiestaBoard: Bool {
        fiestaBoard != nil
    }

    var fiestaBoard: FiestaBoardAPI? {
        token.isEmpty ? nil : try? FiestaBoardAPI(address: address, token: token)
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

    func save(address: String, token: String) {
        self.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(self.address, forKey: Self.addressKey)
        Keychain.write(self.token, for: Self.tokenAccount)
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
