import Testing

@testable import ReadoutCore

@Suite struct CoreTopologyTests {
    private let m1Ultra = Array("EEPPPPPPPPEEPPPPPPPP")
    private let m5Ultra = Array("MMMMMMMMMMMMPPPPPPMMMMMMMMMMMMPPPPPP")

    @Test func m1UltraSplitsIntoPerformanceAndEfficiency() {
        let groups = CoreTopology.groups(
            clusterTypes: m1Ultra,
            levels: [
                PerformanceLevel(name: "Performance", coreCount: 16),
                PerformanceLevel(name: "Efficiency", coreCount: 4),
            ], coreCount: 20)
        #expect(
            groups == [
                CoreGroup(name: "Performance", cores: Array(2...9) + Array(12...19)),
                CoreGroup(name: "Efficiency", cores: [0, 1, 10, 11]),
            ])
    }

    @Test func m5UltraNamesItsTwelvePCoresSuperAndItsTwentyFourMCoresPerformance() {
        let groups = CoreTopology.groups(
            clusterTypes: m5Ultra,
            levels: [
                PerformanceLevel(name: "Super", coreCount: 12), PerformanceLevel(name: "Performance", coreCount: 24),
            ],
            coreCount: 36)
        #expect(
            groups == [
                CoreGroup(name: "Super", cores: Array(12...17) + Array(30...35)),
                CoreGroup(name: "Performance", cores: Array(0...11) + Array(18...29)),
            ])
    }

    @Test func equalSizedTiersFallBackToTheKnownOrderOfTheirLetters() {
        let levels = [
            PerformanceLevel(name: "Performance", coreCount: 4), PerformanceLevel(name: "Efficiency", coreCount: 4),
        ]
        let groups = CoreTopology.groups(clusterTypes: Array("EEEEPPPP"), levels: levels, coreCount: 8)
        #expect(
            groups == [
                CoreGroup(name: "Performance", cores: [4, 5, 6, 7]),
                CoreGroup(name: "Efficiency", cores: [0, 1, 2, 3]),
            ])
    }

    @Test func equalSizedTiersWithUnknownLettersStayUnnamed() {
        let levels = [PerformanceLevel(name: "Fast", coreCount: 2), PerformanceLevel(name: "Slow", coreCount: 2)]
        let groups = CoreTopology.groups(clusterTypes: Array("XXYY"), levels: levels, coreCount: 4)
        #expect(groups == [CoreGroup(name: nil, cores: [0, 1]), CoreGroup(name: nil, cores: [2, 3])])
    }

    @Test func tiersWhoseSizesDisagreeWithTheLevelsStayUnnamed() {
        let levels = [
            PerformanceLevel(name: "Performance", coreCount: 2), PerformanceLevel(name: "Efficiency", coreCount: 2),
        ]
        let groups = CoreTopology.groups(clusterTypes: Array("EPPP"), levels: levels, coreCount: 4)
        #expect(groups == [CoreGroup(name: nil, cores: [0]), CoreGroup(name: nil, cores: [1, 2, 3])])
    }

    @Test func moreTiersThanLevelsStayUnnamed() {
        let groups = CoreTopology.groups(
            clusterTypes: Array("PPME"), levels: [PerformanceLevel(name: "Performance", coreCount: 4)], coreCount: 4)
        #expect(groups.map(\.name) == [nil, nil, nil])
        #expect(groups.flatMap(\.cores).sorted() == [0, 1, 2, 3])
    }

    @Test func coresWithoutClusterTypesFormOneGroupNamedAfterTheOnlyLevel() {
        let groups = CoreTopology.groups(
            clusterTypes: [], levels: [PerformanceLevel(name: "Performance", coreCount: 4)], coreCount: 4)
        #expect(groups == [CoreGroup(name: "Performance", cores: [0, 1, 2, 3])])
    }

    @Test func coresWithoutClusterTypesAndSeveralLevelsFormOneUnnamedGroup() {
        let levels = [
            PerformanceLevel(name: "Super", coreCount: 12), PerformanceLevel(name: "Performance", coreCount: 24),
        ]
        #expect(
            CoreTopology.groups(clusterTypes: [], levels: levels, coreCount: 36)
                == [CoreGroup(name: nil, cores: Array(0..<36))])
        #expect(
            CoreTopology.groups(clusterTypes: Array("PP"), levels: levels, coreCount: 36)
                == [CoreGroup(name: nil, cores: Array(0..<36))])
    }

    @Test func noCoresMeansNoGroups() {
        #expect(CoreTopology.groups(clusterTypes: [], levels: [], coreCount: 0).isEmpty)
    }

    @Test func rowsHoldAtMostTheGivenNumberOfCores() {
        #expect(CoreTopology.rows(Array(0..<5), maxPerRow: 2) == [[0, 1], [2, 3], [4]])
        #expect(CoreTopology.rows(Array(0..<4), maxPerRow: 64) == [[0, 1, 2, 3]])
        #expect(CoreTopology.rows([], maxPerRow: 64).isEmpty)
    }
}
