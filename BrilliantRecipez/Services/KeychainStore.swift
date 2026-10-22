import Foundation
import Security

enum KeychainStore {
    private static var service: String {
        "com.loganvoss.brilliantrecipez.grok" + (AppEnvironment.isUITesting ? ".uitests" : "")
    }
    private static var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service, kSecAttrAccount as String: "api-key"]
    }

    static func read() throws -> String {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else { throw StoreError.keychain }
        return key
    }

    static func save(_ key: String) throws {
        if key.isEmpty { try delete(); return }
        let attributes: [String: Any] = [kSecValueData as String: Data(key.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let result = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if result == errSecItemNotFound {
            var item = query
            attributes.forEach { item[$0.key] = $0.value }
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw StoreError.keychain }
        } else if result != errSecSuccess { throw StoreError.keychain }
    }

    static func delete() throws {
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw StoreError.keychain }
    }
}

enum StoreError: LocalizedError {
    case keychain, photo, library
    var errorDescription: String? {
        switch self {
        case .keychain: "Your API key could not be accessed securely. Unlock your device and try again."
        case .photo: "This photo could not be opened. Choose a different photo or enter ingredients yourself."
        case .library: "Your recipe collection could not be saved. Your existing saved file has been kept."
        }
    }
}
