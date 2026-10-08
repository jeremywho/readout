import Observation
import ReadoutCore
import ReadoutSystem

@MainActor
@Observable
final class ProcessMonitor {
    enum Mode: Sendable {
        case network
        case cpu
        case memory
    }

    private(set) var topCPU: [ProcessUsage] = []
    private(set) var topMemory: [ProcessUsage] = []
    private(set) var topTraffic: [ProcessTraffic] = []
    private(set) var processesUnavailable = false
    private(set) var trafficUnavailable = false
    private(set) var localAddresses: [String] = []
    private(set) var publicIP: String?
    private(set) var interfaceDisplayName: String?
    private var isFixture = false
    private let publicIPProvider = PublicIPProvider()

    func run(_ mode: Mode, interface: String?) async {
        guard !isFixture else { return }
        if mode == .network {
            if let interface {
                localAddresses = LocalAddresses.addresses(interface: interface)
                interfaceDisplayName = InterfaceInfo.displayName(bsdName: interface)
            }
            publicIP = await publicIPProvider.current()
        }
        while !Task.isCancelled {
            switch mode {
            case .network:
                let output = await ProcessRunner.run(
                    "/usr/bin/nettop", ["-P", "-L", "2", "-d", "-s", "1", "-x", "-J", "bytes_in,bytes_out"], timeout: 5)
                trafficUnavailable = output == nil
                topTraffic = output.map { NettopParser.top(NettopParser.parseLastSample($0), limit: 5) } ?? []
            case .cpu, .memory:
                let output = await ProcessRunner.run("/bin/ps", ["-Aceo", "pid=,pcpu=,rss=,comm="], timeout: 5)
                processesUnavailable = output == nil
                let all = output.map(PSParser.parse) ?? []
                topCPU = PSParser.topByCPU(all, limit: 5)
                topMemory = PSParser.topByMemory(all, limit: 5)
            }
            try? await Task.sleep(for: .seconds(2))
        }
    }

    static func fixture() -> ProcessMonitor {
        let monitor = ProcessMonitor()
        monitor.isFixture = true
        monitor.localAddresses = ["192.168.0.42", "fe80::1c2b:3d4e:5f60:7182%en1"]
        monitor.publicIP = "203.0.113.24"
        monitor.interfaceDisplayName = "Wi-Fi"
        monitor.topTraffic = [
            ProcessTraffic(name: "Safari", pid: 812, bytesIn: 48_000, bytesOut: 3_100),
            ProcessTraffic(name: "Music", pid: 640, bytesIn: 9_400, bytesOut: 600),
            ProcessTraffic(name: "mDNSResponder", pid: 211, bytesIn: 1_200, bytesOut: 900),
        ]
        monitor.topCPU = [
            ProcessUsage(pid: 415, cpuPercent: 17.1, residentBytes: 140_896 * 1024, name: "WindowServer"),
            ProcessUsage(pid: 812, cpuPercent: 9.4, residentBytes: 812_000 * 1024, name: "Safari"),
            ProcessUsage(pid: 1201, cpuPercent: 3.0, residentBytes: 512_000 * 1024, name: "Xcode"),
        ]
        monitor.topMemory = [
            ProcessUsage(pid: 1201, cpuPercent: 3.0, residentBytes: 2_812_000 * 1024, name: "Xcode"),
            ProcessUsage(pid: 812, cpuPercent: 9.4, residentBytes: 812_000 * 1024, name: "Safari"),
            ProcessUsage(pid: 415, cpuPercent: 17.1, residentBytes: 140_896 * 1024, name: "WindowServer"),
        ]
        return monitor
    }
}
