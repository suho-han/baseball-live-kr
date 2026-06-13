import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public protocol HTTPSession: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPSession {}

public protocol KboLiveAPIClient: Sendable {
    func fetchTodayGames(date: String?) async throws -> TodayGamesResponseDTO
    func fetchGameDetail(gameId: String, date: String?) async throws -> GameDetailResponseDTO
}

public enum KboLiveAPIError: Error, Sendable, Equatable {
    case invalidBaseURL
    case invalidResponse
    case unexpectedStatusCode(Int)
    case emptyResponse
}

public struct URLSessionKboLiveAPIClient: KboLiveAPIClient, Sendable {
    public let baseURL: URL

    private let session: any HTTPSession
    private let decoder: JSONDecoder

    public init(
        baseURL: URL,
        session: any HTTPSession = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    public func fetchTodayGames(date: String? = nil) async throws -> TodayGamesResponseDTO {
        let request = try makeRequest(path: "/games/today", date: date)
        let data = try await perform(request)
        return try decoder.decode(TodayGamesResponseDTO.self, from: data)
    }

    public func fetchGameDetail(gameId: String, date: String? = nil) async throws -> GameDetailResponseDTO {
        let request = try makeRequest(path: "/games/\(gameId)", date: date)
        let data = try await perform(request)
        return try decoder.decode(GameDetailResponseDTO.self, from: data)
    }

    private func makeRequest(path: String, date: String?) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw KboLiveAPIError.invalidBaseURL
        }

        let normalizedPath: String
        if path.hasPrefix("/") {
            normalizedPath = path
        } else {
            normalizedPath = "/" + path
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if basePath.isEmpty {
            components.path = normalizedPath
        } else {
            components.path = "/" + basePath + normalizedPath
        }

        if let date, date.isEmpty == false {
            components.queryItems = [
                URLQueryItem(name: "date", value: date)
            ]
        }

        guard let url = components.url else {
            throw KboLiveAPIError.invalidBaseURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw KboLiveAPIError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw KboLiveAPIError.unexpectedStatusCode(httpResponse.statusCode)
        }

        guard data.isEmpty == false else {
            throw KboLiveAPIError.emptyResponse
        }

        return data
    }
}
