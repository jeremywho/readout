public enum FanSpeed {
    public static let plausibleRange: ClosedRange<Double> = 0...20_000
    public static let maximumFans = 10

    public static func plausible(_ rpm: Double) -> Double? {
        plausibleRange.contains(rpm) ? rpm : nil
    }

    public static func count(fromSMCValue value: Double) -> Int {
        guard let count = Int(exactly: value), (0...maximumFans).contains(count) else { return 0 }
        return count
    }
}
