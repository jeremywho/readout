public struct ThroughputSample: Sendable, Equatable {
    public var upBytesPerSecond: Double
    public var downBytesPerSecond: Double
    public var upBytes: UInt64
    public var downBytes: UInt64

    public init(upBytesPerSecond: Double, downBytesPerSecond: Double, upBytes: UInt64, downBytes: UInt64) {
        self.upBytesPerSecond = upBytesPerSecond
        self.downBytesPerSecond = downBytesPerSecond
        self.upBytes = upBytes
        self.downBytes = downBytes
    }
}

public struct RateMeter: Sendable {
    private struct Reading: Sendable {
        var up: UInt64
        var down: UInt64
        var seconds: Double
    }

    private var previous: Reading?

    public init() {}

    public mutating func update(up: UInt64, down: UInt64, at seconds: Double) -> ThroughputSample? {
        let current = Reading(up: up, down: down, seconds: seconds)
        guard let last = previous, seconds > last.seconds else {
            if previous == nil { previous = current }
            return nil
        }
        previous = current
        let elapsed = seconds - last.seconds
        let upBytes = CounterDelta.bytes(previous: last.up, current: up)
        let downBytes = CounterDelta.bytes(previous: last.down, current: down)
        return ThroughputSample(
            upBytesPerSecond: Double(upBytes) / elapsed,
            downBytesPerSecond: Double(downBytes) / elapsed,
            upBytes: upBytes,
            downBytes: downBytes
        )
    }

    public mutating func reset() {
        previous = nil
    }
}
