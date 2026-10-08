import Darwin
import Foundation
import SystemConfiguration

public actor PublicIPProvider {
    private let session: URLSession
    private var cached: (address: String, fetchedAt: Date)?

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func current() async -> String? {
        if let cached, Date().timeIntervalSince(cached.fetchedAt) < 300 { return cached.address }
        guard let url = URL(string: "https://api.ipify.org") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        guard let result = try? await session.data(for: request),
            (result.1 as? HTTPURLResponse)?.statusCode == 200
        else { return cached?.address }
        let text = String(decoding: result.0, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        let allowed = CharacterSet(charactersIn: "0123456789abcdefABCDEF.:")
        guard !text.isEmpty, text.count <= 45, text.unicodeScalars.allSatisfy(allowed.contains) else {
            return cached?.address
        }
        cached = (text, Date())
        return text
    }
}

public enum LocalAddresses {
    public static func addresses(interface: String) -> [String] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [] }
        defer { freeifaddrs(head) }
        var result: [String] = []
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = pointer.pointee
            guard String(cString: entry.ifa_name) == interface, let address = entry.ifa_addr else { continue }
            let family = Int32(address.pointee.sa_family)
            guard family == AF_INET || family == AF_INET6 else { continue }
            let length = socklen_t(family == AF_INET ? MemoryLayout<sockaddr_in>.size : MemoryLayout<sockaddr_in6>.size)
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(address, length, &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                result.append(String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self))
            }
        }
        return result
    }
}

public enum InterfaceInfo {
    public static func displayName(bsdName: String) -> String {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return bsdName }
        for interface in interfaces where (SCNetworkInterfaceGetBSDName(interface) as String?) == bsdName {
            return (SCNetworkInterfaceGetLocalizedDisplayName(interface) as String?) ?? bsdName
        }
        return bsdName
    }
}
