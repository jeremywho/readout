import Testing

@testable import ReadoutCore

@Suite struct ByteRateFormatterTests {
    @Test(arguments: [
        (0.0, "0 B/s"),
        (999.0, "999 B/s"),
        (999.6, "1 KB/s"),
        (1_000.0, "1 KB/s"),
        (25_000.0, "25 KB/s"),
        (999_000.0, "999 KB/s"),
        (999_600.0, "1.0 MB/s"),
        (1_000_000.0, "1.0 MB/s"),
        (9_940_000.0, "9.9 MB/s"),
        (9_960_000.0, "10.0 MB/s"),
        (19_000_000.0, "19.0 MB/s"),
        (99_940_000.0, "99.9 MB/s"),
        (99_960_000.0, "100 MB/s"),
        (125_000_000.0, "125 MB/s"),
        (999_600_000.0, "1.0 GB/s"),
        (12_340_000_000.0, "12.3 GB/s"),
        (1_000_000_000.0, "1.0 GB/s"),
        (2_500_000_000_000.0, "2500 GB/s"),
    ])
    func boundaries(value: Double, expected: String) {
        #expect(ByteRateFormatter.string(bytesPerSecond: value) == expected)
    }

    @Test(arguments: [-5.0, Double.nan, Double.infinity, -Double.infinity])
    func nonFiniteAndNegativeRenderAsZero(value: Double) {
        #expect(ByteRateFormatter.string(bytesPerSecond: value) == "0 B/s")
    }
}
