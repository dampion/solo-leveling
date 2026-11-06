import Foundation

struct Streak: Codable, Equatable {
    private(set) var days: Int = 0
    private(set) var lastLogin: Date?
    private(set) var lastIncrement: Date?

    mutating func recordLogin(at now: Date) {
        guard let lastLogin, let lastIncrement, days > 0 else {
            self = Streak(days: 1, lastLogin: now, lastIncrement: now)
            return
        }
        if now < lastLogin || now < lastIncrement {
            // Preserve the count, but restart both clocks after a clock rollback.
            self.lastLogin = now
            self.lastIncrement = now
            return
        }
        if now.timeIntervalSince(lastLogin) > 86_400 {
            days = 1
            self.lastIncrement = now
        } else if now.timeIntervalSince(lastIncrement) >= 86_400 {
            days += 1
            self.lastIncrement = now
        }
        self.lastLogin = now
    }
}

final class StreakStore {
    private let defaults: UserDefaults
    private let key = "loginStreak.v1"
    private(set) var value: Streak

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        value = defaults.data(forKey: key)
            .flatMap { try? JSONDecoder().decode(Streak.self, from: $0) } ?? Streak()
    }

    func recordLogin(at date: Date) {
        value.recordLogin(at: date)
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }
}
