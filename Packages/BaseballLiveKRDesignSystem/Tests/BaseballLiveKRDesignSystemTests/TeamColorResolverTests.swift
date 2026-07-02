import Testing
@testable import BaseballLiveKRDesignSystem

struct TeamColorResolverTests {
    @Test func usesLightForegroundForDarkTeamColors() {
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "LG"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "KT"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "OB"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "HT"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "LT"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "SK"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "NC"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "SS"))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "WO"))
    }

    @Test func keepsTeamColorForegroundForBrightTeamColors() {
        #expect(!TeamColorResolver.usesLightForeground(forTeamID: "HH"))
        #expect(!TeamColorResolver.usesLightForeground(forTeamID: "HANWHA"))
    }

    @Test func normalizesWhitespaceAndFullTeamIdentifiers() {
        #expect(TeamColorResolver.usesLightForeground(forTeamID: " kt "))
        #expect(TeamColorResolver.usesLightForeground(forTeamID: "Doosan"))
        #expect(!TeamColorResolver.usesLightForeground(forTeamID: "hanwha"))
    }

    @Test func resolvesSingleLetterLogoTokens() {
        #expect(TeamColorResolver.logoLetter(forTeamID: "HT", fallbackName: "KIA") == "K")
        #expect(TeamColorResolver.logoLetter(forTeamID: "LG", fallbackName: "LG") == "L")
        #expect(TeamColorResolver.logoLetter(forTeamID: "OB", fallbackName: "두산") == "D")
        #expect(TeamColorResolver.logoLetter(forTeamID: "SK", fallbackName: "SSG") == "S")
        #expect(TeamColorResolver.logoLetter(forTeamID: "NC", fallbackName: "NC") == "N")
        #expect(TeamColorResolver.logoLetter(forTeamID: nil, fallbackName: "ABC") == "A")
    }
}
