import CReadout
import ReadoutCore

public struct TemperatureReading: Sendable, Equatable {
    public var summary: TemperatureSummary
    public var fanRPMs: [Double]

    public init(summary: TemperatureSummary, fanRPMs: [Double]) {
        self.summary = summary
        self.fanRPMs = fanRPMs
    }
}

public final class SMCSampler {
    private var smc = readout_smc()
    private let isOpen: Bool
    private var sensorKeys: [UInt32]?
    private var fanKeys: [UInt32] = []

    public init() {
        isOpen = readout_smc_open(&smc) == 0
    }

    deinit {
        if isOpen { readout_smc_close(&smc) }
    }

    public func sample() -> TemperatureReading? {
        guard isOpen else { return nil }
        let keys = sensorKeys ?? discoverKeys()
        let summary = SensorClassifier.summarize(keys.compactMap(readSensor))
        guard summary.cpuCelsius != nil || summary.gpuCelsius != nil else { return nil }
        return TemperatureReading(summary: summary, fanRPMs: fanKeys.compactMap(readValue))
    }

    public func allTemperatureSensors() -> [SensorValue] {
        guard isOpen else { return [] }
        return allKeys().filter { FourCC.text($0).hasPrefix("T") }.compactMap(readSensor)
    }

    private func discoverKeys() -> [UInt32] {
        let sensors = allKeys().filter { SensorClassifier.kind(ofKey: FourCC.text($0)) != nil }
        sensorKeys = sensors
        let fanCount = readValue(FourCC.code("FNum")).map { Int($0) } ?? 0
        fanKeys = (0..<min(max(fanCount, 0), 10)).map { FourCC.code("F\($0)Ac") }
        return sensors
    }

    private func allKeys() -> [UInt32] {
        var count: UInt32 = 0
        guard readout_smc_key_count(&smc, &count) == 0 else { return [] }
        return (0..<count).compactMap { index in
            var key: UInt32 = 0
            return readout_smc_key_at(&smc, index, &key) == 0 ? key : nil
        }
    }

    private func readValue(_ key: UInt32) -> Double? {
        var bytes = [UInt8](repeating: 0, count: 32)
        var size: UInt32 = 0
        var type: UInt32 = 0
        guard readout_smc_read(&smc, key, &bytes, &size, &type) == 0 else { return nil }
        return SMCValue.decode(bytes: Array(bytes.prefix(Int(size))), type: type)
    }

    private func readSensor(_ key: UInt32) -> SensorValue? {
        readValue(key).map { SensorValue(key: FourCC.text(key), celsius: $0) }
    }
}
