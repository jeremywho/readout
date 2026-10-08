import Testing

@testable import ReadoutCore

@Suite struct RingBufferTests {
    @Test func startsEmpty() {
        let buffer = RingBuffer<Int>(capacity: 3)
        #expect(buffer.elements.isEmpty)
        #expect(buffer.last == nil)
        #expect(buffer.count == 0)
    }

    @Test func keepsInsertionOrderBelowCapacity() {
        var buffer = RingBuffer<Int>(capacity: 3)
        buffer.append(1)
        buffer.append(2)
        #expect(buffer.elements == [1, 2])
        #expect(buffer.last == 2)
    }

    @Test func overflowDropsTheOldest() {
        var buffer = RingBuffer<Int>(capacity: 3)
        for value in 1...5 { buffer.append(value) }
        #expect(buffer.elements == [3, 4, 5])
        #expect(buffer.last == 5)
        #expect(buffer.count == 3)
    }

    @Test func capacityOneHoldsOnlyTheNewest() {
        var buffer = RingBuffer<Int>(capacity: 1)
        buffer.append(7)
        buffer.append(8)
        #expect(buffer.elements == [8])
        #expect(buffer.last == 8)
    }
}
