import Testing

@testable import ReadoutCore

@Suite struct SensorClassifierTests {
    @Test(arguments: [
        ("Tp00", SensorKind?.some(.cpu)), ("Tp2c", .cpu), ("Tg0z", .gpu), ("TpD0", nil), ("TpDX", nil),
        ("TC10", nil), ("Ta05", nil), ("Tp0", nil), ("Tp00x", nil), ("tp00", nil),
    ])
    func classifiesKeys(key: String, expected: SensorKind?) {
        #expect(SensorClassifier.kind(ofKey: key) == expected)
    }

    @Test func recordedM1UltraDumpMatchesIStatCalibration() throws {
        let summary = SensorClassifier.summarize(M1UltraFixture.all)
        let cpu = try #require(summary.cpuCelsius)
        let gpu = try #require(summary.gpuCelsius)
        #expect(abs(cpu - 41.2705) < 0.0001)
        #expect(abs(gpu - 35.606875) < 0.0001)
        #expect(Int(TemperatureUnit.convert(celsius: cpu, to: .fahrenheit).rounded()) == 106)
        #expect(summary.hottest == SensorValue(key: "Tp02", celsius: 58.61))
    }

    @Test func implausibleValuesAreExcluded() {
        let values = [
            SensorValue(key: "Tp00", celsius: 40), SensorValue(key: "Tp01", celsius: 200),
            SensorValue(key: "Tp02", celsius: -1), SensorValue(key: "Tp04", celsius: .nan),
            SensorValue(key: "Tg04", celsius: 0),
        ]
        let summary = SensorClassifier.summarize(values)
        #expect(summary.cpuCelsius == 40)
        #expect(summary.gpuCelsius == nil)
        #expect(summary.hottest == SensorValue(key: "Tp00", celsius: 40))
    }

    @Test func noSensorsMeansEmptySummary() {
        #expect(SensorClassifier.summarize([]) == TemperatureSummary(cpuCelsius: nil, gpuCelsius: nil, hottest: nil))
    }
}
