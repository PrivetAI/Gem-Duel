import SwiftUI
import WebKit

struct GemQuestBattleWebPanel: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let gemQuestBattleWebView = WKWebView()
        if let url = URL(string: urlString) {
            gemQuestBattleWebView.load(URLRequest(url: url))
        }
        return gemQuestBattleWebView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Do NOT reload URL here.
    }
}
