enum MeterKind: String, CaseIterable, Identifiable, Sendable {
    case temperature
    case network
    case disk
    case cpu
    case memory

    var id: String { rawValue }

    var autosaveName: String { "com.daughhetee.Readout.\(rawValue)" }

    var title: String {
        switch self {
        case .temperature: "CPU Temperature"
        case .network: "Network"
        case .disk: "Disk"
        case .cpu: "CPU"
        case .memory: "Memory"
        }
    }
}
