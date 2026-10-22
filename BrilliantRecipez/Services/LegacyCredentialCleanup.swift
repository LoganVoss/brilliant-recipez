import Foundation
import Security

/// A deletion-only migration from v0.1. No credential is read or retained.
enum LegacyCredentialCleanup {
    @MainActor
    @discardableResult
    static func run() -> Bool {
        removeStoredCredentials(isUITesting: AppEnvironment.isUITesting, defaults: AppEnvironment.defaults)
    }

    /// UI tests only touch the old test namespace. Repeated calls safely retry a locked Keychain.
    @discardableResult
    static func removeStoredCredentials(isUITesting: Bool, defaults: UserDefaults) -> Bool {
        defaults.removeObject(forKey: "textModel")
        defaults.removeObject(forKey: "visionModel")
        let service = "com.loganvoss.brilliantrecipez.grok" + (isUITesting ? ".uitests" : "")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "api-key"
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
