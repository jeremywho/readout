import Testing

@testable import ReadoutCore

@Suite struct MenuBarTextTests {
    @Test func networkWithoutSampleShowsPlaceholders() {
        let text = MenuBarText.network(nil)
        #expect(text.up == "—")
        #expect(text.down == "—")
    }

    @Test func networkFormatsBothDirections() {
        let sample = ThroughputSample(upBytesPerSecond: 25_000, downBytesPerSecond: 61_000, upBytes: 0, downBytes: 0)
        let text = MenuBarText.network(sample)
        #expect(text.up == "25 KB/s")
        #expect(text.down == "61 KB/s")
    }

    @Test(arguments: [
        (Optional(81.2), "81%"),
        (Optional(4.5), "5%"),
        (Optional(-3.0), "0%"),
        (Optional(140.0), "100%"),
        (Optional(Double.nan), "—"),
        (nil, "—"),
    ])
    func percent(value: Double?, expected: String) {
        #expect(MenuBarText.percent(value) == expected)
    }
}
