import Foundation
import Observation
import Security

/// Where FiestaBoard is and the token for it: the address in the defaults,
/// the token in the Keychain, as it opens everything the API can do.
@MainActor @Observable
final class Settings {
    private static let addressKey = "serverAddress"
    private static let tokenAccount = "apiToken"

    var address: String
    var token: String

    init() {
        address = UserDefaults.standard.string(forKey: Self.addressKey) ?? ""
        token = Keychain.read(Self.tokenAccount) ?? ""
    }

    var isComplete: Bool {
        Demo.on || (try? api()) != nil && !token.isEmpty
    }

    func api() throws -> FiestaBoardAPI {
        try FiestaBoardAPI(address: address, token: token)
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
