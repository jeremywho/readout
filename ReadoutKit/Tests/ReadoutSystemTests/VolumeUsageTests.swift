import CReadout
import Testing

@Suite struct VolumeUsageTests {
    @Test func dataVolumeReportsSpaceUsed() {
        var used: Int64 = 0
        #expect(readout_read_volume_used("/System/Volumes/Data", &used) == 0)
        #expect(used > 0)
    }

    @Test func missingPathFails() {
        var used: Int64 = 0
        #expect(readout_read_volume_used("/nonexistent/readout-volume", &used) == -1)
    }
}
