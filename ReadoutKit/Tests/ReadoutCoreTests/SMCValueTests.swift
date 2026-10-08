import Testing

@testable import ReadoutCore

@Suite struct SMCValueTests {
    @Test func fourCCRoundTrips() {
        #expect(FourCC.code("flt ") == 0x666C_7420)
        #expect(FourCC.text(0x666C_7420) == "flt ")
        #expect(FourCC.text(FourCC.code("F0Ac")) == "F0Ac")
    }

    @Test func decodesRecordedFanAndPowerFloats() throws {
        let rpm = try #require(SMCValue.decode(bytes: [0x71, 0x8F, 0xA7, 0x44], type: FourCC.code("flt ")))
        #expect(abs(rpm - 1340.48) < 0.01)
        #expect(SMCValue.decode(bytes: [0x00, 0xC0, 0x5A, 0x45], type: FourCC.code("flt ")) == 3500)
        let watts = try #require(SMCValue.decode(bytes: [0x90, 0x60, 0x8C, 0x41], type: FourCC.code("flt ")))
        #expect(abs(watts - 17.547) < 0.001)
    }

    @Test func decodesIntegerAndFixedPointTypes() {
        #expect(SMCValue.decode(bytes: [0x02], type: FourCC.code("ui8 ")) == 2)
        #expect(SMCValue.decode(bytes: [0x01, 0x02], type: FourCC.code("ui16")) == 258)
        #expect(SMCValue.decode(bytes: [0x00, 0x00, 0x01, 0x00], type: FourCC.code("ui32")) == 256)
        #expect(SMCValue.decode(bytes: [0x1A, 0x80], type: FourCC.code("sp78")) == 26.5)
        #expect(SMCValue.decode(bytes: [0xFF, 0x80], type: FourCC.code("sp78")) == -0.5)
        #expect(SMCValue.decode(bytes: [0x14, 0x00], type: FourCC.code("fpe2")) == 1280)
    }

    @Test func rejectsUnknownTypesAndShortBuffers() {
        #expect(SMCValue.decode(bytes: [0, 0, 0, 0], type: FourCC.code("ch8*")) == nil)
        #expect(SMCValue.decode(bytes: [0x00, 0xC0], type: FourCC.code("flt ")) == nil)
        #expect(SMCValue.decode(bytes: [], type: FourCC.code("ui8 ")) == nil)
    }
}
