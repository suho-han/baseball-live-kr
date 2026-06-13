import Foundation

public struct KboLiveEnvironment: Sendable, Equatable {
    public let baseURL: URL
    public let pollingInterval: Duration

    public init(baseURL: URL, pollingInterval: Duration = .seconds(15)) {
        self.baseURL = baseURL
        self.pollingInterval = pollingInterval
    }
}
