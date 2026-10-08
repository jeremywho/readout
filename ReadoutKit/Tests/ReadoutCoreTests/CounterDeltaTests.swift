import Testing

@testable import ReadoutCore

@Suite struct CounterDeltaTests {
    @Test func bytesIncreaseIsTheDifference() {
        #expect(CounterDelta.bytes(previous: 1_000, current: 1_500) == 500)
    }

    @Test func bytesBeyondThe32BitRangeAreExact() {
        #expect(CounterDelta.bytes(previous: 4_294_967_000, current: 4_294_968_000) == 1_000)
    }

    @Test func bytesDecreaseIsTreatedAsAReset() {
        #expect(CounterDelta.bytes(previous: 9_000, current: 10) == 0)
    }

    @Test func ticksWrapAround32Bits() {
        #expect(CounterDelta.ticks(previous: UInt32.max - 9, current: 5) == 15)
    }

    @Test func ticksWithoutWrapAreTheDifference() {
        #expect(CounterDelta.ticks(previous: 100, current: 175) == 75)
    }
}
