import SwiftUI
import WebKit

struct GemDuelWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let gemDuelWebView = WKWebView()
        gemDuelWebView.scrollView.contentInsetAdjustmentBehavior = .always
        gemDuelWebView.isOpaque = true
        gemDuelWebView.backgroundColor = .black
        if let url = URL(string: urlString) {
            gemDuelWebView.load(URLRequest(url: url))
        }
        return gemDuelWebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Do NOT reload URL here.
    }
}
