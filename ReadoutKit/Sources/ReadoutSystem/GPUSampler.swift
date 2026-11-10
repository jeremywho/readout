import CReadout
import ReadoutCore

public struct GPUReading: Sendable, Equatable {
    public var utilizationPercent: Double
    public var memoryInUseBytes: UInt64?
    public var model: String?

    public init(utilizationPercent: Double, memoryInUseBytes: UInt64?, model: String?) {
        self.utilizationPercent = utilizationPercent
        self.memoryInUseBytes = memoryInUseBytes
        self.model = model
    }
}

/// With several GPUs, the reading is the busiest one's.
public struct GPUSampler: Sendable {
    public init() {}

    public func sample() -> GPUReading? {
        var gpu = readout_gpu()
        guard readout_read_gpu(&gpu) == 0 else { return nil }
        let model = withUnsafeBytes(of: gpu.model) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        return GPUReading(
            utilizationPercent: GPUMath.utilizationPercent(Int(gpu.utilization_percent)),
            memoryInUseBytes: gpu.has_memory_in_use != 0 ? gpu.memory_in_use : nil,
            model: model.isEmpty ? nil : model)
    }
}
