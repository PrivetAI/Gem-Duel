import SwiftUI

@main
struct GemQuestBattleApp: App {
    @State private var gemQuestBattleLinkReady: Bool? = nil
    private let gemQuestBattleSourceLink = "https://example.com"
    private let gemQuestBattleCheckDomain = "example"

    @StateObject private var store = SaveStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = gemQuestBattleLinkReady {
                    if ready {
                        GemQuestBattleWebPanel(urlString: gemQuestBattleSourceLink)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        RootView()
                            .environmentObject(store)
                    }
                } else {
                    GemQuestBattleLoadingScreen()
                        .onAppear { checkGemQuestBattleLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private func checkGemQuestBattleLink() {
        guard let url = URL(string: gemQuestBattleSourceLink) else {
            gemQuestBattleLinkReady = false
            return
        }
        var completed = false
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = GemQuestBattleRedirectTracker(checkDomain: gemQuestBattleCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                guard !completed else { return }
                completed = true
                if tracker.foundCheckDomain {
                    gemQuestBattleLinkReady = false
                    return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.gemQuestBattleCheckDomain) {
                    gemQuestBattleLinkReady = false
                    return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.gemQuestBattleCheckDomain) {
                    gemQuestBattleLinkReady = false
                    return
                }
                if error != nil {
                    gemQuestBattleLinkReady = false
                    return
                }
                gemQuestBattleLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            guard !completed else { return }
            completed = true
            gemQuestBattleLinkReady = false
        }
    }
}

final class GemQuestBattleRedirectTracker: NSObject, URLSessionTaskDelegate {
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
