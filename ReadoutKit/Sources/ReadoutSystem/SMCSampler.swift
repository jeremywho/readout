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
    private struct Key {
        var code: UInt32
        var size: UInt32
        var type: UInt32
    }

    private var smc = readout_smc()
    private let isOpen: Bool
    private var sensorKeys: [Key]?
    private var fanKeys: [Key] = []
    private var cadence: SampleCadence
    private var lastReading: TemperatureReading?

    public init(interval: Double = 2) {
        cadence = SampleCadence(interval: interval)
        isOpen = readout_smc_open(&smc) == 0
    }

    deinit {
        if isOpen { readout_smc_close(&smc) }
    }

    public func sample(at seconds: Double) -> TemperatureReading? {
        guard isOpen else { return nil }
        guard cadence.isDue(at: seconds) else { return lastReading }
        let keys = sensorKeys ?? discoverKeys()
        let summary = SensorClassifier.summarize(keys.compactMap(readSensor))
        lastReading =
            summary.cpuCelsius != nil || summary.gpuCelsius != nil
            ? TemperatureReading(
                summary: summary, fanRPMs: fanKeys.compactMap(readValue).compactMap(FanSpeed.plausible)) : nil
        return lastReading
    }

    public func allTemperatureSensors() -> [SensorValue] {
        guard isOpen else { return [] }
        return allKeyCodes().filter { FourCC.text($0).hasPrefix("T") }.compactMap(describe).compactMap(readSensor)
    }

    private func discoverKeys() -> [Key] {
        let sensors = allKeyCodes().filter { SensorClassifier.kind(ofKey: FourCC.text($0)) != nil }.compactMap(describe)
        sensorKeys = sensors
        let fanCount = describe(FourCC.code("FNum")).flatMap(readValue).map(FanSpeed.count(fromSMCValue:)) ?? 0
        fanKeys = (0..<fanCount).compactMap { describe(FourCC.code("F\($0)Ac")) }
        return sensors
    }

    private func allKeyCodes() -> [UInt32] {
        var count: UInt32 = 0
        guard readout_smc_key_count(&smc, &count) == 0 else { return [] }
        return (0..<count).compactMap { index in
            var key: UInt32 = 0
            return readout_smc_key_at(&smc, index, &key) == 0 ? key : nil
        }
    }

    private func describe(_ code: UInt32) -> Key? {
        var size: UInt32 = 0
        var type: UInt32 = 0
        guard readout_smc_key_info(&smc, code, &size, &type) == 0 else { return nil }
        return Key(code: code, size: size, type: type)
    }

    private func readValue(_ key: Key) -> Double? {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard readout_smc_read_known(&smc, key.code, key.size, &bytes) == 0 else { return nil }
        return SMCValue.decode(bytes: Array(bytes.prefix(Int(key.size))), type: key.type)
    }

    private func readSensor(_ key: Key) -> SensorValue? {
        readValue(key).map { SensorValue(key: FourCC.text(key.code), celsius: $0) }
    }
}
