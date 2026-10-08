public enum SensorKind: Sendable, Equatable {
    case cpu
    case gpu
}

public struct SensorValue: Sendable, Equatable {
    public var key: String
    public var celsius: Double

    public init(key: String, celsius: Double) {
        self.key = key
        self.celsius = celsius
    }
}

public struct TemperatureSummary: Sendable, Equatable {
    public var cpuCelsius: Double?
    public var gpuCelsius: Double?
    public var hottest: SensorValue?

    public init(cpuCelsius: Double?, gpuCelsius: Double?, hottest: SensorValue?) {
        self.cpuCelsius = cpuCelsius
        self.gpuCelsius = gpuCelsius
        self.hottest = hottest
    }
}

public enum SensorClassifier {
    public static let plausibleRange: ClosedRange<Double> = 5...130

    public static func kind(ofKey key: String) -> SensorKind? {
        let characters = Array(key)
        guard characters.count == 4, characters[0] == "T", characters[2].isASCII, characters[2].isNumber else {
            return nil
        }
        switch characters[1] {
        case "p": return .cpu
        case "g": return .gpu
        default: return nil
        }
    }

    public static func summarize(_ values: [SensorValue]) -> TemperatureSummary {
        let usable = values.filter { plausibleRange.contains($0.celsius) && kind(ofKey: $0.key) != nil }
        func mean(of sensorKind: SensorKind) -> Double? {
            let readings = usable.filter { kind(ofKey: $0.key) == sensorKind }.map(\.celsius)
            return readings.isEmpty ? nil : readings.reduce(0, +) / Double(readings.count)
        }
        return TemperatureSummary(
            cpuCelsius: mean(of: .cpu),
            gpuCelsius: mean(of: .gpu),
            hottest: usable.max { $0.celsius < $1.celsius }
        )
    }
}
