import CryptoKit
import Foundation
import Security

struct PINStore {
    private struct Credential: Codable {
        let salt: Data
        let digest: Data
    }

    enum StoreError: LocalizedError {
        case keychain(OSStatus), invalidCredential

        var errorDescription: String? {
            switch self {
            case .keychain(let status): return "無法存取安全儲存空間（\(status)），請稍後再試。"
            case .invalidCredential: return "密碼資料無法讀取，請重試。"
            }
        }
    }

    private var query: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Bundle.main.bundleIdentifier ?? "SoloLeveling",
         kSecAttrAccount as String: "appPIN.v1"]
    }

    func initializeIfNeeded() throws {
        if try read() == nil { try save("0304") }
    }

    func verify(_ pin: String) throws -> Bool {
        guard PINRules.isValid(pin), let credential = try read() else { return false }
        let candidate = hash(pin, salt: credential.salt)
        guard candidate.count == credential.digest.count else { return false }
        return zip(candidate, credential.digest).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }

    func save(_ pin: String) throws {
        guard PINRules.isValid(pin) else { throw StoreError.invalidCredential }
        var bytes = [UInt8](repeating: 0, count: 32)
        let randomStatus = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard randomStatus == errSecSuccess else { throw StoreError.keychain(randomStatus) }
        let salt = Data(bytes)
        let data = try JSONEncoder().encode(Credential(salt: salt, digest: hash(pin, salt: salt)))
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let addStatus = SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw StoreError.keychain(addStatus) }
        } else if status != errSecSuccess {
            throw StoreError.keychain(status)
        }
    }

    private func read() throws -> Credential? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
        guard let data = result as? Data,
              let credential = try? JSONDecoder().decode(Credential.self, from: data) else {
            throw StoreError.invalidCredential
        }
        return credential
    }

    private func hash(_ pin: String, salt: Data) -> Data {
        Data(SHA256.hash(data: salt + Data(pin.utf8)))
    }
}
