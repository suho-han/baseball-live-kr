import Foundation
#if canImport(KboLiveCore)
import KboLiveCore
#endif

enum AppRuntime {
    static func makeClient() -> GameFeedClient {
        GameFeedClient.live(baseURL: backendBaseURL)
    }

    static func makeClient(baseURL: URL) -> GameFeedClient {
        GameFeedClient.live(baseURL: baseURL)
    }

    static var backendBaseURL: URL {
        if let configured = ProcessInfo.processInfo.environment["KBO_LIVE_BASE_URL"],
           let url = URL(string: configured) {
            return url
        }

        if let stored = UserDefaults.standard.string(forKey: KboLiveEnvironment.backendBaseURLDefaultsKey),
           let url = URL(string: stored) {
            return url
        }

        return KboLiveEnvironment.defaultBaseURL
    }
}
