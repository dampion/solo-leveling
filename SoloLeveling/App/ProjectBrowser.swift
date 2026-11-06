import SwiftUI
import WebKit

enum SideProject: String, CaseIterable, Identifiable {
    case japanese, brandIsland
    var id: String { rawValue }
    var title: String { self == .japanese ? "日本語學習" : "王品品牌島" }
    var symbol: String { self == .japanese ? "character.book.closed" : "fork.knife" }
    var url: URL {
        switch self {
        case .japanese: return URL(string: "https://language-web.evanchen79-ad0.workers.dev/")!
        case .brandIsland: return URL(string: "http://brand-island.evanchen79-ad0.workers.dev/")!
        }
    }
}

@MainActor
final class BrowserModel: NSObject, ObservableObject, WKNavigationDelegate, WKUIDelegate {
    let webView: WKWebView
    private let initialURL: URL
    @Published var isLoading = true
    @Published var canGoBack = false
    @Published var errorMessage: String?
    private var observations: [NSKeyValueObservation] = []

    init(url: URL) {
        initialURL = url
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        observations = [
            webView.observe(\.isLoading, options: [.initial, .new]) { [weak self] _, change in
                let loading = change.newValue ?? false
                Task { @MainActor [weak self] in self?.isLoading = loading }
            },
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] _, change in
                let canGoBack = change.newValue ?? false
                Task { @MainActor [weak self] in self?.canGoBack = canGoBack }
            }
        ]
        webView.load(URLRequest(url: url))
    }

    func reload() {
        errorMessage = nil
        if webView.url == nil { webView.load(URLRequest(url: initialURL)) }
        else { webView.reload() }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        errorMessage = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) { handle(error) }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!,
                 withError error: Error) { handle(error) }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        errorMessage = "網頁已停止運作，請重新載入。"
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        let scheme = url.scheme?.lowercased()
        if scheme == "http" || scheme == "https" || url.absoluteString == "about:blank" {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
            if ["mailto", "tel"].contains(scheme ?? "") {
                UIApplication.shared.open(url)
            } else {
                errorMessage = "此連結類型無法在 App 中開啟。"
            }
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
           let scheme = navigationAction.request.url?.scheme?.lowercased(),
           ["http", "https"].contains(scheme) {
            webView.load(navigationAction.request)
        }
        return nil
    }

    private func handle(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        errorMessage = "無法載入網頁，請確認網路連線後重試。\n\(error.localizedDescription)"
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ProjectBrowser: View {
    let project: SideProject
    @Environment(\.dismiss) private var dismiss
    @StateObject private var browser: BrowserModel

    init(project: SideProject) {
        self.project = project
        _browser = StateObject(wrappedValue: BrowserModel(url: project.url))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WebView(webView: browser.webView)
                if let error = browser.errorMessage {
                    ContentUnavailableView {
                        Label("載入失敗", systemImage: "wifi.exclamationmark")
                    } description: {
                        Text(error)
                    } actions: {
                        Button("重新載入") { browser.reload() }.buttonStyle(.borderedProminent)
                    }.background(.background)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if browser.isLoading { ProgressView().frame(maxWidth: .infinity).padding(6) }
            }
            .navigationTitle(project.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("關閉") { dismiss() } }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { browser.webView.goBack() } label: { Image(systemName: "chevron.left") }
                        .disabled(!browser.canGoBack).accessibilityLabel("上一頁")
                    Button { browser.reload() } label: { Image(systemName: "arrow.clockwise") }
                        .accessibilityLabel("重新整理")
                }
            }
        }
    }
}
