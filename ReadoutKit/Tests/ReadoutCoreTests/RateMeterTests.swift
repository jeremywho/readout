import Testing

@testable import ReadoutCore

@Suite struct RateMeterTests {
    @Test func firstUpdateHasNoRate() {
        var meter = RateMeter()
        #expect(meter.update(up: 100, down: 200, at: 0) == nil)
    }

    @Test func oneSecondApartGivesBytesPerSecond() {
        var meter = RateMeter()
        _ = meter.update(up: 1_000, down: 5_000, at: 10)
        let sample = meter.update(up: 26_000, down: 66_000, at: 11)
        #expect(
            sample
                == ThroughputSample(
                    upBytesPerSecond: 25_000, downBytesPerSecond: 61_000, upBytes: 25_000, downBytes: 61_000))
    }

    @Test func unevenIntervalScalesTheRate() {
        var meter = RateMeter()
        _ = meter.update(up: 0, down: 0, at: 1)
        let sample = meter.update(up: 500, down: 1_000, at: 1.5)
        #expect(sample?.upBytesPerSecond == 1_000)
        #expect(sample?.downBytesPerSecond == 2_000)
    }

    @Test func counterDecreaseReadsZero() {
        var meter = RateMeter()
        _ = meter.update(up: 9_000_000, down: 9_000_000, at: 0)
        let sample = meter.update(up: 10, down: 20, at: 1)
        #expect(sample == ThroughputSample(upBytesPerSecond: 0, downBytesPerSecond: 0, upBytes: 0, downBytes: 0))
    }

    @Test func longGapAveragesInsteadOfSpiking() {
        var meter = RateMeter()
        _ = meter.update(up: 0, down: 0, at: 0)
        let sample = meter.update(up: 3_600_000, down: 7_200_000, at: 3_600)
        #expect(sample?.upBytesPerSecond == 1_000)
        #expect(sample?.downBytesPerSecond == 2_000)
    }

    @Test func nonIncreasingTimeHasNoRate() {
        var meter = RateMeter()
        _ = meter.update(up: 0, down: 0, at: 5)
        #expect(meter.update(up: 100, down: 100, at: 5) == nil)
        #expect(meter.update(up: 200, down: 200, at: 4) == nil)
    }

    @Test func resetForgetsThePreviousReading() {
        var meter = RateMeter()
        _ = meter.update(up: 0, down: 0, at: 0)
        meter.reset()
        #expect(meter.update(up: 1_000, down: 1_000, at: 1) == nil)
        #expect(meter.update(up: 2_000, down: 3_000, at: 2)?.downBytesPerSecond == 2_000)
    }
}
