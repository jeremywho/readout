import CReadout
import Foundation
import ReadoutCore
import SystemConfiguration

public struct InterfaceCounters: Sendable, Equatable {
    public var name: String
    public var bytesIn: UInt64
    public var bytesOut: UInt64

    public init(name: String, bytesIn: UInt64, bytesOut: UInt64) {
        self.name = name
        self.bytesIn = bytesIn
        self.bytesOut = bytesOut
    }
}

public enum InterfaceCountersReader {
    public static func readAll() -> [InterfaceCounters]? {
        var buffer = [readout_interface_counters](repeating: readout_interface_counters(), count: 256)
        let count = buffer.withUnsafeMutableBufferPointer {
            readout_read_interface_counters($0.baseAddress, Int32($0.count))
        }
        guard count >= 0 else { return nil }
        return buffer.prefix(Int(count)).map { entry in
            let name = withUnsafeBytes(of: entry.name) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
            return InterfaceCounters(name: name, bytesIn: entry.bytes_in, bytesOut: entry.bytes_out)
        }
    }
}

public enum PrimaryInterface {
    public static func current() -> String? {
        guard let value = SCDynamicStoreCopyValue(nil, "State:/Network/Global/IPv4" as CFString) as? [String: Any]
        else { return nil }
        return value["PrimaryInterface"] as? String
    }
}

public enum InterfaceSelection: Sendable, Equatable {
    case automatic
    case named(String)

    public init(preference: String) {
        self = preference.isEmpty ? .automatic : .named(preference)
    }
}

public struct NetworkReading: Sendable, Equatable {
    public var interface: String?
    public var throughput: ThroughputSample?
    public var sessionBytesIn: UInt64
    public var sessionBytesOut: UInt64

    public init(interface: String?, throughput: ThroughputSample?, sessionBytesIn: UInt64, sessionBytesOut: UInt64) {
        self.interface = interface
        self.throughput = throughput
        self.sessionBytesIn = sessionBytesIn
        self.sessionBytesOut = sessionBytesOut
    }
}

public final class NetworkSampler {
    public typealias CountersSource = () -> [InterfaceCounters]?
    public typealias PrimarySource = () -> String?

    public var selection: InterfaceSelection = .automatic
    private let counters: CountersSource
    private let primary: PrimarySource
    private var meter = RateMeter()
    private var currentInterface: String?
    private var sessionIn: UInt64 = 0
    private var sessionOut: UInt64 = 0

    public init(
        counters: @escaping CountersSource = InterfaceCountersReader.readAll,
        primary: @escaping PrimarySource = PrimaryInterface.current
    ) {
        self.counters = counters
        self.primary = primary
    }

    public func sample(at seconds: Double) -> NetworkReading {
        let name: String?
        switch selection {
        case .automatic: name = primary()
        case .named(let chosen): name = chosen
        }
        guard let name, let entry = counters()?.first(where: { $0.name == name }) else {
            meter.reset()
            currentInterface = nil
            return NetworkReading(
                interface: nil, throughput: nil, sessionBytesIn: sessionIn, sessionBytesOut: sessionOut)
        }
        if name != currentInterface {
            meter.reset()
            currentInterface = name
        }
        let throughput = meter.update(up: entry.bytesOut, down: entry.bytesIn, at: seconds)
        if let throughput {
            sessionIn += throughput.downBytes
            sessionOut += throughput.upBytes
        }
        return NetworkReading(
            interface: name, throughput: throughput, sessionBytesIn: sessionIn, sessionBytesOut: sessionOut)
    }
}
