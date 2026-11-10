enum MeterKind: String, CaseIterable, Identifiable, Sendable {
    case temperature
    case network
    case disk
    case cpu
    case gpu
    case memory

    var id: String { rawValue }

    static let autosavePrefix = "com.daughhetee.Readout"

    var title: String {
        switch self {
        case .temperature: "CPU Temperature"
        case .network: "Network"
        case .disk: "Disk"
        case .cpu: "CPU"
        case .gpu: "GPU"
        case .memory: "Memory"
        }
    }
}
