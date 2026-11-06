import XCTest
@testable import SoloLevelingCore

final class UnlockSessionTests: XCTestCase {
    func testSuccessfulUnlockCanOnlyBeConsumedOnce() {
        var session = UnlockSession()
        let token = session.generation
        XCTAssertTrue(session.unlock(token: token))
        XCTAssertFalse(session.unlock(token: token))
        XCTAssertTrue(session.isUnlocked)
    }

    func testBackgroundInvalidatesPendingBiometrics() {
        var session = UnlockSession()
        let staleToken = session.generation
        session.lock()
        XCTAssertFalse(session.unlock(token: staleToken))
        XCTAssertFalse(session.isUnlocked)
        XCTAssertTrue(session.unlock(token: session.generation))
    }

    func testReturningFromBackgroundRequiresNewUnlock() {
        var session = UnlockSession()
        XCTAssertTrue(session.unlock(token: session.generation))
        session.lock()
        XCTAssertFalse(session.isUnlocked)
        XCTAssertTrue(session.unlock(token: session.generation))
    }

    func testPINRequiresExactlyFourASCIIDigits() {
        XCTAssertTrue(PINRules.isValid("0304"))
        XCTAssertTrue(PINRules.isValid("0000"))
        for pin in ["", "123", "12345", "abcd", "１２３４", "١٢٣٤", "12 4", "123\n"] {
            XCTAssertFalse(PINRules.isValid(pin), pin)
        }
    }
}
