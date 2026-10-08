import Foundation

public enum ByteRateFormatter {
    private static let units = ["B/s", "KB/s", "MB/s", "GB/s"]

    public static func string(bytesPerSecond: Double) -> String {
        guard bytesPerSecond.isFinite, bytesPerSecond > 0 else { return "0 B/s" }
        var value = bytesPerSecond
        var unitIndex = 0
        while value >= 1000, unitIndex < units.count - 1 {
            value /= 1000
            unitIndex += 1
        }
        return render(value, unitIndex: unitIndex)
    }

    private static func render(_ value: Double, unitIndex: Int) -> String {
        if unitIndex >= 2, value < 99.95 {
            return String(format: "%.1f", value) + " " + units[unitIndex]
        }
        let rounded = value.rounded()
        if rounded >= 1000, unitIndex < units.count - 1 {
            return render(rounded / 1000, unitIndex: unitIndex + 1)
        }
        return "\(Int(rounded)) \(units[unitIndex])"
    }
}
