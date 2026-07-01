import Testing
@testable import KboLiveCore

struct RuntimeStringSettingMigrationTests {
    @Test func oldOnlyValueIsReturnedPersistedToNewKeyAndRemovedFromLegacyKey() {
        let store = MockRuntimeStringSettingStore(values: ["old": "legacy-value"])

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "legacy-value")
        #expect(result.source == .legacy)
        #expect(result.persistedLegacyValue)
        #expect(result.removedLegacyValue)
        #expect(result.destinationUnavailable == false)
        #expect(store.values["new"] == "legacy-value")
        #expect(store.values["old"] == nil)
    }

    @Test func newOnlyValueWinsWithoutTouchingLegacyKey() {
        let store = MockRuntimeStringSettingStore(values: ["new": "new-value"])

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "new-value")
        #expect(result.source == .new)
        #expect(result.persistedLegacyValue == false)
        #expect(result.removedLegacyValue == false)
        #expect(store.values["new"] == "new-value")
    }

    @Test func bothPresentKeepsNewValue() {
        let store = MockRuntimeStringSettingStore(values: [
            "new": "new-value",
            "old": "legacy-value"
        ])

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "new-value")
        #expect(result.source == .new)
        #expect(store.values["new"] == "new-value")
        #expect(store.values["old"] == "legacy-value")
    }

    @Test func oldInaccessibleBehavesLikeMissingValue() {
        let store = MockRuntimeStringSettingStore(
            values: ["old": "legacy-value"],
            unreadableKeys: ["old"]
        )

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == nil)
        #expect(result.source == .missing)
        #expect(result.persistedLegacyValue == false)
        #expect(store.values["new"] == nil)
    }

    @Test func destinationUnavailableStillReturnsReadableLegacyValue() {
        let store = MockRuntimeStringSettingStore(
            values: ["old": "legacy-value"],
            unwritableKeys: ["new"]
        )

        let result = RuntimeStringSettingMigration.resolve(
            store: store,
            newKey: "new",
            legacyKey: "old"
        )

        #expect(result.value == "legacy-value")
        #expect(result.source == .legacy)
        #expect(result.persistedLegacyValue == false)
        #expect(result.removedLegacyValue == false)
        #expect(result.destinationUnavailable)
        #expect(store.values["new"] == nil)
        #expect(store.values["old"] == "legacy-value")
    }

    @Test func environmentUsesNewValueBeforeLegacyValue() {
        let result = RuntimeStringSettingMigration.resolveEnvironmentValue(
            newName: "BASEBALL_LIVE_KR_BASE_URL",
            legacyName: "KBO_LIVE_BASE_URL",
            environment: [
                "BASEBALL_LIVE_KR_BASE_URL": "https://api.suhohan.kr",
                "KBO_LIVE_BASE_URL": "http://127.0.0.1:17361"
            ],
            isValid: { $0.hasPrefix("https://") || $0.hasPrefix("http://") }
        )

        #expect(result.value == "https://api.suhohan.kr")
        #expect(result.source == .new)
    }

    @Test func malformedNewEnvironmentFallsBackToValidLegacyValue() {
        let result = RuntimeStringSettingMigration.resolveEnvironmentValue(
            newName: "BASEBALL_LIVE_KR_BASE_URL",
            legacyName: "KBO_LIVE_BASE_URL",
            environment: [
                "BASEBALL_LIVE_KR_BASE_URL": "not a url",
                "KBO_LIVE_BASE_URL": "http://127.0.0.1:17361"
            ],
            isValid: { $0.hasPrefix("https://") || $0.hasPrefix("http://") }
        )

        #expect(result.value == "http://127.0.0.1:17361")
        #expect(result.source == .legacy)
    }
}

private final class MockRuntimeStringSettingStore: RuntimeStringSettingStore {
    var values: [String: String]
    private let unreadableKeys: Set<String>
    private let unwritableKeys: Set<String>

    init(
        values: [String: String],
        unreadableKeys: Set<String> = [],
        unwritableKeys: Set<String> = []
    ) {
        self.values = values
        self.unreadableKeys = unreadableKeys
        self.unwritableKeys = unwritableKeys
    }

    func string(forKey key: String) -> String? {
        unreadableKeys.contains(key) ? nil : values[key]
    }

    func persistString(_ value: String, forKey key: String) -> Bool {
        guard unwritableKeys.contains(key) == false else {
            return false
        }

        values[key] = value
        return true
    }

    func clearString(forKey key: String) -> Bool {
        values[key] = nil
        return true
    }
}
