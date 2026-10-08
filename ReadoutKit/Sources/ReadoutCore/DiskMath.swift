public enum DiskMath {
    public static func usedPercent(totalBytes: Int64, availableBytes: Int64) -> Double? {
        guard totalBytes > 0, availableBytes >= 0 else { return nil }
        let used = max(totalBytes - availableBytes, 0)
        return Double(used) * 100 / Double(totalBytes)
    }
}
