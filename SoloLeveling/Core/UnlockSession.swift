import Foundation

/// A token prevents stale biometric callbacks and duplicate login events.
struct UnlockSession {
    private(set) var isUnlocked = false
    private(set) var generation = UUID()

    mutating func lock() {
        isUnlocked = false
        generation = UUID()
    }

    mutating func unlock(token: UUID) -> Bool {
        guard token == generation, !isUnlocked else { return false }
        isUnlocked = true
        return true
    }
}

enum PINRules {
    static func isValid(_ pin: String) -> Bool {
        pin.utf8.count == 4 && pin.utf8.allSatisfy { (48...57).contains($0) }
    }
}
