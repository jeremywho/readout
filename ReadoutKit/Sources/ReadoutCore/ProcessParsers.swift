import Foundation

public struct ProcessTraffic: Sendable, Equatable {
    public var name: String
    public var pid: Int32
    public var bytesIn: UInt64
    public var bytesOut: UInt64
    public var total: UInt64 { bytesIn + bytesOut }

    public init(name: String, pid: Int32, bytesIn: UInt64, bytesOut: UInt64) {
        self.name = name
        self.pid = pid
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}

public enum NettopParser {
    public static func parseLastSample(_ output: String) -> [ProcessTraffic] {
        let lines = output.split(whereSeparator: \.isNewline).map(String.init)
        guard let header = lines.lastIndex(where: { $0.hasPrefix(",bytes_in,bytes_out") }) else { return [] }
        return lines[(header + 1)...].compactMap(parseLine)
    }

    public static func top(_ traffic: [ProcessTraffic], limit: Int) -> [ProcessTraffic] {
        let active = traffic.filter { $0.total > 0 }
        let sorted = active.sorted { $0.total != $1.total ? $0.total > $1.total : $0.pid < $1.pid }
        return Array(sorted.prefix(limit))
    }

    static func parseLine(_ line: String) -> ProcessTraffic? {
        var fields = line.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
        if fields.last == "" { fields.removeLast() }
        guard fields.count >= 3,
            let bytesOut = UInt64(fields[fields.count - 1]),
            let bytesIn = UInt64(fields[fields.count - 2])
        else { return nil }
        let label = fields[0..<(fields.count - 2)].joined(separator: ",")
        guard let dot = label.lastIndex(of: "."), let pid = Int32(label[label.index(after: dot)...]) else {
            return nil
        }
        return ProcessTraffic(name: String(label[..<dot]), pid: pid, bytesIn: bytesIn, bytesOut: bytesOut)
    }
}

public struct ProcessUsage: Sendable, Equatable {
    public var pid: Int32
    public var cpuPercent: Double
    public var residentBytes: UInt64
    public var name: String

    public init(pid: Int32, cpuPercent: Double, residentBytes: UInt64, name: String) {
        self.pid = pid
        self.cpuPercent = cpuPercent
        self.residentBytes = residentBytes
        self.name = name
    }
}

public enum PSParser {
    public static func parse(_ output: String) -> [ProcessUsage] {
        output.split(whereSeparator: \.isNewline).compactMap(parseLine)
    }

    public static func topByCPU(_ processes: [ProcessUsage], limit: Int) -> [ProcessUsage] {
        let sorted = processes.sorted {
            $0.cpuPercent != $1.cpuPercent ? $0.cpuPercent > $1.cpuPercent : $0.pid < $1.pid
        }
        return Array(sorted.prefix(limit))
    }

    public static func topByMemory(_ processes: [ProcessUsage], limit: Int) -> [ProcessUsage] {
        let sorted = processes.sorted {
            $0.residentBytes != $1.residentBytes ? $0.residentBytes > $1.residentBytes : $0.pid < $1.pid
        }
        return Array(sorted.prefix(limit))
    }

    static func parseLine(_ line: Substring) -> ProcessUsage? {
        var rest = line.drop(while: \.isWhitespace)
        var fields: [Substring] = []
        for _ in 0..<3 {
            guard let end = rest.firstIndex(where: \.isWhitespace) else { return nil }
            fields.append(rest[..<end])
            rest = rest[end...].drop(while: \.isWhitespace)
        }
        let name = String(rest).trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let pid = Int32(fields[0]), let cpu = Double(fields[1]), let rss = UInt64(fields[2]) else {
            return nil
        }
        return ProcessUsage(pid: pid, cpuPercent: cpu, residentBytes: rss * 1024, name: name)
    }
}
