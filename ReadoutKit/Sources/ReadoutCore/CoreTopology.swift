public struct PerformanceLevel: Sendable, Equatable {
    public var name: String
    public var coreCount: Int

    public init(name: String, coreCount: Int) {
        self.name = name
        self.coreCount = coreCount
    }
}

public struct CoreGroup: Sendable, Equatable {
    public var name: String?
    public var cores: [Int]

    public init(name: String?, cores: [Int]) {
        self.name = name
        self.cores = cores
    }
}

public enum CoreTopology {
    /// Only breaks a tie between tiers of equal size. P outranks E through M4; on M5 the OS names P "Super" and M
    /// "Performance".
    private static let fastestFirst: [Character] = ["P", "M", "E"]

    /// `levels` are the system's performance levels, fastest first. A tier gets a name only when its core count
    /// matches a level; a wrong name is worse than none.
    public static func groups(clusterTypes: [Character], levels: [PerformanceLevel], coreCount: Int) -> [CoreGroup] {
        guard coreCount > 0 else { return [] }
        guard clusterTypes.count == coreCount else {
            let name = levels.count == 1 && levels[0].coreCount == coreCount ? levels[0].name : nil
            return [CoreGroup(name: name, cores: Array(0..<coreCount))]
        }
        var coresByType: [Character: [Int]] = [:]
        for (core, type) in clusterTypes.enumerated() { coresByType[type, default: []].append(core) }
        return named(coresByType, levels: levels)
            ?? coresByType.values.sorted { $0[0] < $1[0] }.map { CoreGroup(name: nil, cores: $0) }
    }

    public static func rows(_ cores: [Int], maxPerRow: Int) -> [[Int]] {
        guard maxPerRow > 0 else { return [cores] }
        return stride(from: 0, to: cores.count, by: maxPerRow).map {
            Array(cores[$0..<min($0 + maxPerRow, cores.count)])
        }
    }

    private static func named(_ coresByType: [Character: [Int]], levels: [PerformanceLevel]) -> [CoreGroup]? {
        guard coresByType.count == levels.count else { return nil }
        var unassigned = coresByType
        var groups: [CoreGroup] = []
        for level in levels {
            let candidates = unassigned.filter { $0.value.count == level.coreCount }.map(\.key)
            let type: Character
            if candidates.count == 1 {
                type = candidates[0]
            } else if candidates.allSatisfy(fastestFirst.contains),
                let ranked = fastestFirst.first(where: candidates.contains)
            {
                type = ranked
            } else {
                return nil
            }
            groups.append(CoreGroup(name: level.name, cores: unassigned.removeValue(forKey: type) ?? []))
        }
        return groups
    }
}
