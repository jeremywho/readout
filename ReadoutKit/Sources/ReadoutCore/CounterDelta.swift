public enum CounterDelta {
    public static func bytes(previous: UInt64, current: UInt64) -> UInt64 {
        current >= previous ? current - previous : 0
    }

    public static func ticks(previous: UInt32, current: UInt32) -> UInt32 {
        current &- previous
    }
}
