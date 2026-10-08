import Testing

@testable import ReadoutSystem

final class FakeNetwork {
    var primary: String?
    var counters: [InterfaceCounters]

    init(primary: String?, counters: [InterfaceCounters]) {
        self.primary = primary
        self.counters = counters
    }

    func set(_ name: String, bytesIn: UInt64, bytesOut: UInt64) {
        counters.removeAll { $0.name == name }
        counters.append(InterfaceCounters(name: name, bytesIn: bytesIn, bytesOut: bytesOut))
    }

    func sampler() -> NetworkSampler {
        NetworkSampler(counters: { self.counters }, primary: { self.primary })
    }
}

@Suite struct NetworkSamplerTests {
    @Test func steadyTrafficProducesRatesOnTheSecondTick() {
        let fake = FakeNetwork(primary: "en1", counters: [])
        fake.set("en1", bytesIn: 1_000, bytesOut: 500)
        let sampler = fake.sampler()
        #expect(sampler.sample(at: 0).throughput == nil)
        fake.set("en1", bytesIn: 62_000, bytesOut: 25_500)
        let reading = sampler.sample(at: 1)
        #expect(reading.interface == "en1")
        #expect(reading.throughput?.downBytesPerSecond == 61_000)
        #expect(reading.throughput?.upBytesPerSecond == 25_000)
    }

    @Test func switchingInterfaceRestartsWithoutSpike() {
        let fake = FakeNetwork(primary: "en0", counters: [])
        fake.set("en0", bytesIn: 100, bytesOut: 100)
        fake.set("en1", bytesIn: 900_000_000_000, bytesOut: 900_000_000_000)
        let sampler = fake.sampler()
        _ = sampler.sample(at: 0)
        fake.primary = "en1"
        let switched = sampler.sample(at: 1)
        #expect(switched.interface == "en1")
        #expect(switched.throughput == nil)
        fake.set("en1", bytesIn: 900_000_002_000, bytesOut: 900_000_001_000)
        #expect(sampler.sample(at: 2).throughput?.downBytesPerSecond == 2_000)
    }

    @Test func missingPrimaryInterfaceYieldsPlaceholderAndRecovers() {
        let fake = FakeNetwork(primary: nil, counters: [])
        fake.set("en0", bytesIn: 0, bytesOut: 0)
        let sampler = fake.sampler()
        let offline = sampler.sample(at: 0)
        #expect(offline.interface == nil)
        #expect(offline.throughput == nil)
        fake.primary = "en0"
        #expect(sampler.sample(at: 1).throughput == nil)
        fake.set("en0", bytesIn: 4_000, bytesOut: 0)
        #expect(sampler.sample(at: 2).throughput?.downBytesPerSecond == 4_000)
    }

    @Test func namedSelectionIgnoresThePrimaryInterface() {
        let fake = FakeNetwork(primary: "en0", counters: [])
        fake.set("en0", bytesIn: 0, bytesOut: 0)
        fake.set("utun3", bytesIn: 0, bytesOut: 0)
        let sampler = fake.sampler()
        sampler.selection = .named("utun3")
        #expect(sampler.sample(at: 0).interface == "utun3")
    }

    @Test func sessionTotalsAccumulateAcrossTicks() {
        let fake = FakeNetwork(primary: "en0", counters: [])
        fake.set("en0", bytesIn: 0, bytesOut: 0)
        let sampler = fake.sampler()
        _ = sampler.sample(at: 0)
        fake.set("en0", bytesIn: 1_000, bytesOut: 10)
        _ = sampler.sample(at: 1)
        fake.set("en0", bytesIn: 3_000, bytesOut: 30)
        let reading = sampler.sample(at: 2)
        #expect(reading.sessionBytesIn == 3_000)
        #expect(reading.sessionBytesOut == 30)
    }

    @Test func preferenceStringMapsToSelection() {
        #expect(InterfaceSelection(preference: "") == .automatic)
        #expect(InterfaceSelection(preference: "en5") == .named("en5"))
    }
}
