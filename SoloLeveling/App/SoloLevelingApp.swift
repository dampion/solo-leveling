import SwiftUI

@main
struct SoloLevelingApp: App {
    @StateObject private var model = AppModel()
    @StateObject private var privacyShield = PrivacyShield()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                if model.isUnlocked {
                    HomeView(model: model)
                } else {
                    LockView(model: model)
                }
            }
            .overlay {
                if scenePhase == .background {
                    Color.black.ignoresSafeArea()
                        .overlay(Image(systemName: "lock.fill").font(.largeTitle))
                }
            }
            .preferredColorScheme(.dark)
            .tint(.cyan)
            .task { if scenePhase == .active { model.becameActive() } }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                privacyShield.coverWindows()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                privacyShield.revealWindows()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { model.enteredBackground() }
                if phase == .active { model.becameActive() }
            }
        }
    }
}

/// Covers presented sheets and web content before the system captures an app snapshot.
/// This visual shield does not lock the session when Face ID temporarily deactivates the app.
@MainActor
final class PrivacyShield: ObservableObject {
    private var covers: [UIView] = []

    func coverWindows() {
        guard covers.isEmpty else { return }
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .filter { !$0.isHidden }
        for window in windows {
            let cover = UIView(frame: window.bounds)
            cover.backgroundColor = .black
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            let icon = UIImageView(image: UIImage(systemName: "lock.fill"))
            icon.tintColor = .systemCyan
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            cover.addSubview(icon)
            NSLayoutConstraint.activate([
                icon.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
                icon.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: 36),
                icon.heightAnchor.constraint(equalToConstant: 44)
            ])
            window.addSubview(cover)
            covers.append(cover)
        }
    }

    func revealWindows() {
        covers.forEach { $0.removeFromSuperview() }
        covers.removeAll()
    }
}

struct LockView: View {
    @ObservedObject var model: AppModel
    @State private var pin = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 52)).foregroundStyle(.cyan)
                        .padding(.top, 70)
                    VStack(spacing: 10) {
                        Text("SOLO LEVELING").font(.title.bold()).tracking(3)
                        Text("每一天，向前一點。").foregroundStyle(.secondary)
                    }
                    VStack(spacing: 16) {
                        PINField(title: "輸入 4 位數密碼", value: $pin)
                            .onSubmit(submit)
                        if let message = model.errorMessage {
                            Text(message).font(.callout).foregroundStyle(.orange)
                                .accessibilityIdentifier("unlockError")
                        }
                        Button(action: submit) {
                            Text("解鎖").frame(maxWidth: .infinity).padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!PINRules.isValid(pin) || model.isAuthenticating)
                        .accessibilityIdentifier("unlockButton")
                        if model.faceIDEnabled {
                            Button { model.authenticateWithFaceID() } label: {
                                Label("使用 Face ID", systemImage: "faceid")
                            }
                            .disabled(model.isAuthenticating)
                        }
                        if model.isAuthenticating { ProgressView("正在驗證身分…") }
                    }
                    .padding(24)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
                }
                .frame(maxWidth: 440)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
            .background(Color(red: 0.035, green: 0.045, blue: 0.08))
        }
    }

    private func submit() {
        model.unlock(pin: pin)
        pin = ""
    }
}

struct PINField: View {
    let title: String
    @Binding var value: String

    var body: some View {
        SecureField(title, text: $value)
            .keyboardType(.numberPad)
            .textContentType(.password)
            .textFieldStyle(.roundedBorder)
            .onChange(of: value) { _, newValue in
                value = String(newValue.filter { $0.isASCII && $0.isNumber }.prefix(4))
            }
    }
}
