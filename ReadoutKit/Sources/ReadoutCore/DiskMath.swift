public enum DiskMath {
    public static func usedPercent(
        volumeUsedBytes: Int64, totalBytes: Int64, availableForImportantUsage: Int64, containerFreeBytes: Int64
    ) -> Double? {
        guard totalBytes > 0, volumeUsedBytes >= 0, availableForImportantUsage >= 0, containerFreeBytes >= 0 else {
            return nil
        }
        let purgeable = max(availableForImportantUsage - containerFreeBytes, 0)
        let used = min(max(volumeUsedBytes - purgeable, 0), totalBytes)
        return Double(used) * 100 / Double(totalBytes)
    }
}
