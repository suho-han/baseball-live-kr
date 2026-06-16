import Testing
@testable import KboLiveFeatures

struct KboDisplayDateFormatterTests {
    @Test func fullDateIncludesWeekday() {
        #expect(KboDisplayDateFormatter.fullDate("20260618") == "2026.06.18 (목)")
    }

    @Test func fullDateFallsBackForInvalidInput() {
        #expect(KboDisplayDateFormatter.fullDate("2026-06-18") == "2026-06-18")
    }
}
