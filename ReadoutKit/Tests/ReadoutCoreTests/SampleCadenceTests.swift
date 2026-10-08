import Testing

@testable import ReadoutCore

@Suite struct SampleCadenceTests {
    private func due(_ cadence: inout SampleCadence, at times: [Double]) -> [Bool] {
        times.map { cadence.isDue(at: $0) }
    }

    @Test func firstCallIsDue() {
        var cadence = SampleCadence(interval: 2)
        #expect(due(&cadence, at: [0]) == [true])
    }

    @Test func callsInsideTheIntervalAreNotDue() {
        var cadence = SampleCadence(interval: 2)
        #expect(due(&cadence, at: [10, 11, 11.9]) == [true, false, false])
    }

    @Test func callAtOrAfterTheIntervalIsDueAndRestartsIt() {
        var cadence = SampleCadence(interval: 2)
        #expect(due(&cadence, at: [10, 12, 13, 14.5]) == [true, true, false, true])
    }

    @Test func clockGoingBackwardsIsDue() {
        var cadence = SampleCadence(interval: 2)
        #expect(due(&cadence, at: [10, 3]) == [true, true])
    }
}
