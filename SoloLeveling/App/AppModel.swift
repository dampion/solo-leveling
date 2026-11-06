import LocalAuthentication
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var session = UnlockSession()
    @Published private(set) var streak: Streak
    @Published private(set) var previousLogin: Date?
    @Published private(set) var faceIDEnabled: Bool
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    private let defaults: UserDefaults
    private let streakStore: StreakStore
    private let pinStore = PINStore()
    private var context: LAContext?
    private var didAttemptAutomaticUnlock = false
    private var biometricRequest: UUID?

    var isUnlocked: Bool { session.isUnlocked }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        streakStore = StreakStore(defaults: defaults)
        streak = streakStore.value
        faceIDEnabled = defaults.bool(forKey: "faceIDEnabled")
    }

    func becameActive() {
        guard !isUnlocked, !didAttemptAutomaticUnlock else { return }
        didAttemptAutomaticUnlock = true
        do {
            try pinStore.initializeIfNeeded()
            if faceIDEnabled { authenticateWithFaceID() }
        } catch { errorMessage = error.localizedDescription }
    }

    func enteredBackground() {
        biometricRequest = nil
        context?.invalidate()
        context = nil
        isAuthenticating = false
        session.lock()
        didAttemptAutomaticUnlock = false
        errorMessage = nil
    }

    func unlock(pin: String) {
        guard !isUnlocked, !isAuthenticating else { return }
        do {
            try pinStore.initializeIfNeeded()
            if try pinStore.verify(pin) {
                completeUnlock(token: session.generation)
            } else {
                errorMessage = "密碼不正確，請重新輸入。"
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func authenticateWithFaceID() {
        guard faceIDEnabled, !isUnlocked, !isAuthenticating else { return }
        let token = session.generation
        evaluateFaceID(reason: "解鎖 Solo Leveling") { [weak self] success in
            guard let self else { return }
            if success { self.completeUnlock(token: token) }
            else { self.errorMessage = "Face ID 未完成，請輸入 App 密碼。" }
        }
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        guard isUnlocked, !isAuthenticating else { return }
        if !enabled {
            faceIDEnabled = false
            defaults.set(false, forKey: "faceIDEnabled")
            return
        }
        evaluateFaceID(reason: "啟用 Face ID，供下次解鎖使用") { [weak self] success in
            guard let self, self.isUnlocked else { return }
            if success {
                self.faceIDEnabled = true
                self.defaults.set(true, forKey: "faceIDEnabled")
            } else {
                self.errorMessage = "無法啟用 Face ID，請確認裝置已設定 Face ID 並允許使用。"
            }
        }
    }

    func changePIN(old: String, new: String, confirmation: String) -> Bool {
        guard isUnlocked else { return false }
        guard PINRules.isValid(new) else {
            errorMessage = "新密碼必須為 4 位數字。"
            return false
        }
        guard new == confirmation else {
            errorMessage = "兩次輸入的新密碼不同。"
            return false
        }
        do {
            guard try pinStore.verify(old) else {
                errorMessage = "目前密碼不正確。"
                return false
            }
            try pinStore.save(new)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func completeUnlock(token: UUID) {
        guard session.unlock(token: token) else { return }
        previousLogin = streakStore.value.lastLogin
        streakStore.recordLogin(at: Date())
        streak = streakStore.value
        errorMessage = nil
    }

    private func evaluateFaceID(reason: String, completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "輸入 App 密碼"
        context.localizedCancelTitle = "取消"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error),
              context.biometryType == .faceID else {
            completion(false)
            return
        }
        let request = UUID()
        biometricRequest = request
        self.context = context
        isAuthenticating = true
        errorMessage = nil
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
            [weak self] success, _ in
            Task { @MainActor in
                guard let self, self.biometricRequest == request else { return }
                self.biometricRequest = nil
                self.context = nil
                self.isAuthenticating = false
                completion(success)
            }
        }
    }
}
