import Testing

@testable import ReadoutCore

@Suite struct FanSpeedTests {
    @Test(arguments: [1340.5, 0.0, 20_000.0])
    func plausibleSpeedsPassThrough(rpm: Double) {
        #expect(FanSpeed.plausible(rpm) == rpm)
    }

    @Test(arguments: [Double.nan, Double.infinity, -Double.infinity, -1.0, 20_000.5, 9.3e18])
    func implausibleSpeedsAreDropped(rpm: Double) {
        #expect(FanSpeed.plausible(rpm) == nil)
    }

    @Test(arguments: [(2.0, 2), (0.0, 0)])
    func fanCountsFromWholeNumbers(value: Double, expected: Int) {
        #expect(FanSpeed.count(fromSMCValue: value) == expected)
    }

    @Test(arguments: [Double.nan, Double.infinity, -1.0, 2.5, 11.0])
    func fanCountsRejectNonsense(value: Double) {
        #expect(FanSpeed.count(fromSMCValue: value) == 0)
    }
}
