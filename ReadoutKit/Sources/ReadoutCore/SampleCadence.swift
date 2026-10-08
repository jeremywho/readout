public struct SampleCadence: Sendable {
    public let interval: Double
    private var lastSampled: Double?

    public init(interval: Double) {
        self.interval = interval
    }

    public mutating func isDue(at seconds: Double) -> Bool {
        if let lastSampled, seconds >= lastSampled, seconds - lastSampled < interval { return false }
        lastSampled = seconds
        return true
    }
}
