import SwiftUI

@main
struct GemDuelApp: App {
    @State private var gemDuelLinkReady: Bool? = nil
    private let gemDuelSourceLink = "https://gemduel.org/click.php"
    private let gemDuelCheckDomain = "termsfeed.com"

    @StateObject private var store = SaveStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = gemDuelLinkReady {
                    if ready {
                        GemDuelWebPanel(urlString: gemDuelSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                            .environmentObject(store)
                    }
                } else {
                    GemDuelLoadingScreen()
                        .onAppear { checkGemDuelLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func checkGemDuelLink() {
        guard let url = URL(string: gemDuelSourceLink) else {
            gemDuelLinkReady = false
            return
        }
        var completed = false
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = GemDuelRedirectTracker(checkDomain: gemDuelCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                guard !completed else { return }
                completed = true
                if tracker.foundCheckDomain {
                    gemDuelLinkReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.gemDuelCheckDomain) {
                    gemDuelLinkReady = false
                    return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.gemDuelCheckDomain) {
                    gemDuelLinkReady = false
                    return
                }
                if error != nil {
                    gemDuelLinkReady = false
                    return
                }
                gemDuelLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard !completed else { return }
            completed = true
            gemDuelLinkReady = false
        }
    }
}

final class GemDuelRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String

    init(checkDomain: String) {
        self.checkDomain = checkDomain
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
