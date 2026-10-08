public enum MenuBarText {
    public static let placeholder = "—"

    public static func network(_ sample: ThroughputSample?) -> (up: String, down: String) {
        guard let sample else { return (placeholder, placeholder) }
        return (
            ByteRateFormatter.string(bytesPerSecond: sample.upBytesPerSecond),
            ByteRateFormatter.string(bytesPerSecond: sample.downBytesPerSecond)
        )
    }

    public static func percent(_ value: Double?) -> String {
        guard let value, value.isFinite else { return placeholder }
        return "\(Int(min(max(value, 0), 100).rounded()))%"
    }
}
