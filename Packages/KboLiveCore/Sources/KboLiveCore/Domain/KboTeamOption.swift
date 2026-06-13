import Foundation

public struct KboTeamOption: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public extension KboTeamOption {
    static let all: [KboTeamOption] = [
        KboTeamOption(id: "LG", name: "LG"),
        KboTeamOption(id: "OB", name: "두산"),
        KboTeamOption(id: "SK", name: "SSG"),
        KboTeamOption(id: "SS", name: "삼성"),
        KboTeamOption(id: "HT", name: "KIA"),
        KboTeamOption(id: "KT", name: "KT"),
        KboTeamOption(id: "LT", name: "롯데"),
        KboTeamOption(id: "HH", name: "한화"),
        KboTeamOption(id: "NC", name: "NC"),
        KboTeamOption(id: "WO", name: "키움")
    ]
}

public extension Game {
    func involves(teamID: String) -> Bool {
        awayTeam.id == teamID || homeTeam.id == teamID
    }

    func team(named teamID: String) -> Team? {
        if awayTeam.id == teamID {
            return awayTeam
        }

        if homeTeam.id == teamID {
            return homeTeam
        }

        return nil
    }
}
