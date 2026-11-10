import Testing

@testable import ReadoutCore

@Suite struct GPUMathTests {
    @Test(arguments: [(0, 0.0), (37, 37.0), (100, 100.0), (-4, 0.0), (140, 100.0)])
    func utilizationStaysBetweenZeroAndOneHundred(raw: Int, expected: Double) {
        #expect(GPUMath.utilizationPercent(raw) == expected)
    }
}
