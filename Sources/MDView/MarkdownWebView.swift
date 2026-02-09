import SwiftUI
import WebKit

struct MarkdownWebView: NSViewRepresentable {
    let markdown: String
    let baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = webView

        webView.loadHTMLString(HTMLTemplate.html, baseURL: baseURL)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.updateContent(markdown)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        private var pendingContent: String?
        private var isPageLoaded = false

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isPageLoaded = true
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
