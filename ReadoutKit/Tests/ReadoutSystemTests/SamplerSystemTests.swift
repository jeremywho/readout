import Foundation
import Testing

@testable import ReadoutSystem

@Suite struct SamplerSystemTests {
    @Test func realInterfaceCountersAndPrimaryInterfaceAreReadable() throws {
        let counters = try #require(InterfaceCountersReader.readAll())
        let primary = try #require(PrimaryInterface.current())
        #expect(counters.contains { $0.name == primary })
    }

    @Test func cpuSamplerReportsSaneLoadOnTheSecondTick() async throws {
        let sampler = CPUSampler()
        #expect(sampler.sample() == nil)
        try await Task.sleep(for: .milliseconds(300))
        let reading = try #require(sampler.sample())
        #expect(reading.cores.count == ProcessInfo.processInfo.processorCount)
        #expect((0...1).contains(reading.total.total))
        #expect(reading.loadAverage.count == 3)
    }

    @Test func cpuSamplerGroupsCoresIntoTheTiersTheSystemReports() async throws {
        let sampler = CPUSampler()
        _ = sampler.sample()
        try await Task.sleep(for: .milliseconds(300))
        let reading = try #require(sampler.sample())
        let coreCount = ProcessInfo.processInfo.processorCount
        let levels = CPUSampler.readLevels()
        let expectedNames: [String?] = levels.isEmpty ? [nil] : levels.map(\.name)
        let expectedSizes = levels.isEmpty ? [coreCount] : levels.map(\.coreCount)
        #expect(reading.groups.map(\.name) == expectedNames)
        #expect(reading.groups.map(\.cores.count) == expectedSizes)
        #expect(reading.groups.flatMap(\.cores).sorted() == Array(0..<coreCount))
    }

    @Test func memorySamplerReportsPressureAndBreakdown() throws {
        let reading = try #require(MemorySampler().sample())
        #expect((0...100).contains(reading.pressurePercent))
        let breakdown = try #require(reading.breakdown)
        #expect(breakdown.used > 0)
        #expect(breakdown.used <= reading.physicalBytes)
    }

    @Test func diskSamplerReportsCapacityAndRates() throws {
        let sampler = DiskSampler()
        let first = try #require(sampler.sample(at: 0))
        #expect(first.totalBytes > 0)
        #expect(first.availableBytes <= first.totalBytes)
        #expect((0...100).contains(first.usedPercent))
        #expect(first.readBytesPerSecond == nil)
        let second = try #require(sampler.sample(at: 1))
        #expect(second.readBytesPerSecond != nil)
    }
}
