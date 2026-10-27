import SwiftUI
import WebKit

/// Optional browser for the existing full ОМА server. All primary iOS demo screens
/// (including eight interactive modules) work without this connection.
struct ServerPreview: UIViewRepresentable {
    let url: URL

    final class Coordinator: NSObject, WKNavigationDelegate {
        var currentAddress: String?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.allowsInlineMediaPlayback = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.allowsBackForwardNavigationGestures = true
        view.scrollView.keyboardDismissMode = .interactive
        view.isOpaque = false
        view.backgroundColor = .systemBackground
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        let address = url.absoluteString
        guard context.coordinator.currentAddress != address else { return }
        context.coordinator.currentAddress = address
        view.load(URLRequest(url: url, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 20))
    }
}
