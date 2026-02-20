import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    let zoomLevel: Double
    weak var appState: AppState?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private static let resourceBundle: Bundle? = {
        let candidates = [
            Bundle.main.resourceURL?.appendingPathComponent("MDView_MDView.bundle"),
            Bundle.main.bundleURL.appendingPathComponent("MDView_MDView.bundle"),
        ]
        for case let url? in candidates {
            if let bundle = Bundle(url: url) {
                return bundle
            }
        }
        return nil
    }()

    private static let stageDir: URL = {
        let fm = FileManager.default
        let dir = fm.temporaryDirectory.appendingPathComponent("mdview")
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)

        Log.debug("stageDir: \(dir.path)")
        Log.debug("resourceBundle: \(resourceBundle?.bundlePath ?? "nil")")

        let htmlFile = dir.appendingPathComponent("index.html")
        try? HTMLTemplate.html.write(to: htmlFile, atomically: true, encoding: .utf8)

        if let resourceDir = resourceBundle?.resourceURL {
            let contents = (try? fm.contentsOfDirectory(atPath: resourceDir.path)) ?? []
            Log.debug("resourceDir contents: \(contents)")
            for file in contents {
                let src = resourceDir.appendingPathComponent(file)
                let dst = dir.appendingPathComponent(file)
                try? fm.removeItem(at: dst)
                do {
                    try fm.copyItem(at: src, to: dst)
                    Log.debug("copied \(file)")
                } catch {
                    Log.debug("FAILED \(file): \(error)")
                }
            }
        } else {
            Log.debug("resourceURL is nil")
        }

        Log.debug("staged files: \((try? fm.contentsOfDirectory(atPath: dir.path)) ?? [])")

        return dir
    }()

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = true
        webView.pageZoom = zoomLevel
        context.coordinator.webView = webView
        context.coordinator.baseURL = baseURL
        appState?.webView = webView

        let htmlFile = Self.stageDir.appendingPathComponent("index.html")
        webView.loadFileURL(htmlFile, allowingReadAccessTo: URL(fileURLWithPath: "/"))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.baseURL?.absoluteString != baseURL?.absoluteString {
            context.coordinator.baseURL = baseURL
            if let baseURL = baseURL {
                let dir = baseURL.absoluteString
                let escaped = dir.replacingOccurrences(of: "'", with: "\\'")
                webView.evaluateJavaScript("setBaseDir('\(escaped)')") { _, _ in }
            }
        }
        context.coordinator.updateContent(markdown)
        if webView.pageZoom != zoomLevel {
            webView.pageZoom = zoomLevel
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        var baseURL: URL?
        private var pendingContent: String?
        private var isPageLoaded = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
            if let baseURL = baseURL {
                let dir = baseURL.absoluteString
                let escaped = dir.replacingOccurrences(of: "'", with: "\\'")
                webView.evaluateJavaScript("setBaseDir('\(escaped)')") { _, _ in }
            }
            if let content = pendingContent {
                sendToWebView(content)
                pendingContent = nil
            }
        }

        func updateContent(_ markdown: String) {
            if isPageLoaded {
                sendToWebView(markdown)
            } else {
                pendingContent = markdown
            }
        }

        private func sendToWebView(_ markdown: String) {
            guard let webView = webView else { return }
            let encoded = Data(markdown.utf8).base64EncodedString()
            webView.evaluateJavaScript("renderBase64('\(encoded)')") { _, error in
                if let error = error {
                    Log.debug("JS error: \(error.localizedDescription)")
                }
            }
        }

        // Allow navigation to links by opening in default browser
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
}
