import CReadout
import Foundation
import Testing

@Suite struct CReadoutTests {
    private func interfaceCounters() -> [String: (UInt64, UInt64)] {
        var buffer = [readout_interface_counters](repeating: readout_interface_counters(), count: 256)
        let count = buffer.withUnsafeMutableBufferPointer { readout_read_interface_counters($0.baseAddress, 256) }
        var result: [String: (UInt64, UInt64)] = [:]
        for entry in buffer.prefix(Int(max(count, 0))) {
            let name = withUnsafeBytes(of: entry.name) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
            result[name] = (entry.bytes_in, entry.bytes_out)
        }
        return result
    }

    @Test func interfaceCountersIncludeLoopbackAndAreMonotonic() throws {
        let first = interfaceCounters()
        #expect(first["lo0"] != nil)
        let socket = try #require(URL(string: "http://127.0.0.1:9"))
        _ = try? Data(contentsOf: socket)
        let second = interfaceCounters()
        for (name, counters) in first {
            guard let later = second[name] else { continue }
            #expect(later.0 >= counters.0, "\(name) bytes_in went backwards")
            #expect(later.1 >= counters.1, "\(name) bytes_out went backwards")
        }
    }

    @Test func coreTicksCoverEveryProcessor() {
        var buffer = [readout_core_ticks](repeating: readout_core_ticks(), count: 512)
        let count = buffer.withUnsafeMutableBufferPointer { readout_read_core_ticks($0.baseAddress, 512) }
        #expect(Int(count) == ProcessInfo.processInfo.processorCount)
        #expect(buffer.prefix(Int(count)).allSatisfy { $0.idle > 0 })
    }

    @Test func coreKindsAreUnavailableOrMatchTheCoreCount() {
        var kinds = [CChar](repeating: 0, count: 512)
        let count = kinds.withUnsafeMutableBufferPointer { readout_read_core_kinds($0.baseAddress, 512) }
        let valid = kinds.prefix(Int(max(count, 0))).allSatisfy {
            $0 == CChar(UInt8(ascii: "P")) || $0 == CChar(UInt8(ascii: "E"))
        }
        #expect(count == -1 || (Int(count) == ProcessInfo.processInfo.processorCount && valid))
    }

    @Test func vmPagesAndPressureAreReadable() {
        var pages = readout_vm_pages()
        #expect(readout_read_vm_pages(&pages) == 0)
        #expect(pages.page_size >= 4096)
        #expect(pages.wired_pages > 0)
        let level = readout_read_memorystatus_level()
        #expect((0...100).contains(level))
    }

    @Test func swapAndDiskIOAreReadable() {
        var used: UInt64 = 0
        var total: UInt64 = 0
        #expect(readout_read_swap(&used, &total) == 0)
        #expect(used <= total)
        var read: UInt64 = 0
        var written: UInt64 = 0
        #expect(readout_read_disk_io(&read, &written) == 0)
    }
}
