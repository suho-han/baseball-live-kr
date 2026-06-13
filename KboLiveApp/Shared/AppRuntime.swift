import Foundation
#if canImport(KboLiveCore)
import KboLiveCore
#endif

enum AppRuntime {
    static func makeClient() -> GameFeedClient {
        GameFeedClient.live(baseURL: backendBaseURL)
    }

    static var backendBaseURL: URL {
        if let configured = ProcessInfo.processInfo.environment["KBO_LIVE_BASE_URL"],
           let url = URL(string: configured) {
            return url
        }

        return URL(string: "http://127.0.0.1:3000")!
    }

}
