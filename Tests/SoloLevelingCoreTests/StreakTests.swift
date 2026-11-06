import Foundation
import XCTest
@testable import SoloLevelingCore

final class StreakTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_700_000_000)

    func testFirstLoginStartsAtOne() {
        var streak = Streak()
        streak.recordLogin(at: start)
        XCTAssertEqual(streak.days, 1)
        XCTAssertEqual(streak.lastLogin, start)
        XCTAssertEqual(streak.lastIncrement, start)
    }

    func testRepeatedLoginUpdatesActivityWithoutIncrementing() {
        var streak = Streak()
        streak.recordLogin(at: start)
        streak.recordLogin(at: start.addingTimeInterval(3_600))
        XCTAssertEqual(streak.days, 1)
        XCTAssertEqual(streak.lastLogin, start.addingTimeInterval(3_600))
        XCTAssertEqual(streak.lastIncrement, start)
    }

    func testExactlyTwentyFourHoursIncrements() {
        var streak = Streak()
        streak.recordLogin(at: start)
        streak.recordLogin(at: start.addingTimeInterval(86_400))
        XCTAssertEqual(streak.days, 2)
    }

    func testMoreThanTwentyFourHoursWithoutLoginResets() {
        var streak = Streak()
        streak.recordLogin(at: start)
        streak.recordLogin(at: start.addingTimeInterval(86_400))
        let returnDate = start.addingTimeInterval(172_801)
        streak.recordLogin(at: returnDate)
        XCTAssertEqual(streak.days, 1)
        XCTAssertEqual(streak.lastIncrement, returnDate)
    }

    func testIntermediateLoginKeepsStreakAlive() {
        var streak = Streak()
        streak.recordLogin(at: start)
        streak.recordLogin(at: start.addingTimeInterval(20 * 3_600))
        streak.recordLogin(at: start.addingTimeInterval(30 * 3_600))
        XCTAssertEqual(streak.days, 2)
        XCTAssertEqual(streak.lastIncrement, start.addingTimeInterval(30 * 3_600))
        streak.recordLogin(at: start.addingTimeInterval(40 * 3_600))
        XCTAssertEqual(streak.days, 2)
        streak.recordLogin(at: start.addingTimeInterval(54 * 3_600))
        XCTAssertEqual(streak.days, 3)
    }

    func testDuplicateTimestampDoesNotIncrementAgain() {
        var streak = Streak()
        streak.recordLogin(at: start)
        let next = start.addingTimeInterval(86_400)
        streak.recordLogin(at: next)
        streak.recordLogin(at: next)
        XCTAssertEqual(streak.days, 2)
    }

    func testClockRollbackPreservesCountAndResetsClocks() {
        var streak = Streak()
        streak.recordLogin(at: start)
        streak.recordLogin(at: start.addingTimeInterval(86_400))
        let rollback = start.addingTimeInterval(-100)
        streak.recordLogin(at: rollback)
        XCTAssertEqual(streak.days, 2)
        XCTAssertEqual(streak.lastLogin, rollback)
        XCTAssertEqual(streak.lastIncrement, rollback)
        streak.recordLogin(at: rollback.addingTimeInterval(86_400))
        XCTAssertEqual(streak.days, 3)
    }

    func testStatePersistsAcrossStoreInstances() throws {
        let suite = "SoloLevelingTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = StreakStore(defaults: defaults)
        store.recordLogin(at: start)
        store.recordLogin(at: start.addingTimeInterval(86_400))
        let restored = StreakStore(defaults: defaults)
        XCTAssertEqual(restored.value, store.value)
        restored.recordLogin(at: start.addingTimeInterval(86_401))
        XCTAssertEqual(restored.value.days, 2)
    }

    func testCorruptStoredStateStartsFresh() throws {
        let suite = "SoloLevelingTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("invalid".utf8), forKey: "loginStreak.v1")
        let store = StreakStore(defaults: defaults)
        store.recordLogin(at: start)
        XCTAssertEqual(store.value.days, 1)
    }
}
