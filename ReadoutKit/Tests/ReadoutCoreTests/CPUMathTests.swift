import Testing

@testable import ReadoutCore

@Suite struct CPUMathTests {
    @Test func halfBusySplitsUserAndSystem() {
        let load = CPUMath.load(
            previous: CoreTicks(user: 100, system: 100, idle: 100, nice: 0),
            current: CoreTicks(user: 130, system: 120, idle: 150, nice: 0)
        )
        #expect(load == CoreLoad(user: 0.3, system: 0.2))
        #expect(load.total == 0.5)
    }

    @Test func niceCountsAsUser() {
        let load = CPUMath.load(
            previous: CoreTicks(user: 0, system: 0, idle: 0, nice: 0),
            current: CoreTicks(user: 10, system: 0, idle: 80, nice: 10)
        )
        #expect(load == CoreLoad(user: 0.2, system: 0))
    }

    @Test func noElapsedTicksIsIdle() {
        let ticks = CoreTicks(user: 5, system: 5, idle: 5, nice: 5)
        #expect(CPUMath.load(previous: ticks, current: ticks) == .idle)
    }

    @Test func wrappedCountersStillMeasure() {
        let load = CPUMath.load(
            previous: CoreTicks(user: UInt32.max - 49, system: 0, idle: 0, nice: 0),
            current: CoreTicks(user: 50, system: 0, idle: 100, nice: 0)
        )
        #expect(load == CoreLoad(user: 0.5, system: 0))
    }

    @Test func mismatchedCoreCountsYieldNil() {
        let one = [CoreTicks(user: 0, system: 0, idle: 0, nice: 0)]
        #expect(CPUMath.loads(previous: one, current: one + one) == nil)
        #expect(CPUMath.loads(previous: [], current: []) == nil)
    }

    @Test func averageIsPerFieldMean() {
        let average = CPUMath.average([CoreLoad(user: 0.5, system: 0.25), CoreLoad(user: 0.25, system: 0.25)])
        #expect(average == CoreLoad(user: 0.375, system: 0.25))
        #expect(CPUMath.average([]) == .idle)
    }

    @Test func clusterTypeMapsToKind() {
        #expect(CoreKind(clusterType: "E") == .efficiency)
        #expect(CoreKind(clusterType: "P") == .performance)
        #expect(CoreKind(clusterType: "\0") == .performance)
    }
}
