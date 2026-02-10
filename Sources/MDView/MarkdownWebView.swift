import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?
    let zoomLevel: Double

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

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

        if baseURL != nil {
            let tmpDir = FileManager.default.temporaryDirectory
            let tmpFile = tmpDir.appendingPathComponent("mdview-template.html")
            try? HTMLTemplate.html.write(to: tmpFile, atomically: true, encoding: .utf8)
            webView.loadFileURL(tmpFile, allowingReadAccessTo: URL(fileURLWithPath: "/"))
        } else {
            webView.loadHTMLString(HTMLTemplate.html, baseURL: nil)
        }
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
                    print("JS error: \(error.localizedDescription)")
                }
            }
        }

        // Allow navigation to links by opening in default browser
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
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
