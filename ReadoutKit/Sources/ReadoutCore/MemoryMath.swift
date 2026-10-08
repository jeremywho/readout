public struct VMPages: Sendable, Equatable {
    public var internalPages: UInt64
    public var purgeablePages: UInt64
    public var externalPages: UInt64
    public var wiredPages: UInt64
    public var compressorPages: UInt64
    public var pageSize: UInt64

    public init(
        internalPages: UInt64, purgeablePages: UInt64, externalPages: UInt64,
        wiredPages: UInt64, compressorPages: UInt64, pageSize: UInt64
    ) {
        self.internalPages = internalPages
        self.purgeablePages = purgeablePages
        self.externalPages = externalPages
        self.wiredPages = wiredPages
        self.compressorPages = compressorPages
        self.pageSize = pageSize
    }
}

public struct MemoryBreakdown: Sendable, Equatable {
    public var app: UInt64
    public var wired: UInt64
    public var compressed: UInt64
    public var cached: UInt64
    public var used: UInt64 { app + wired + compressed }

    public init(app: UInt64, wired: UInt64, compressed: UInt64, cached: UInt64) {
        self.app = app
        self.wired = wired
        self.compressed = compressed
        self.cached = cached
    }
}

public enum MemoryMath {
    public static func pressurePercent(memorystatusLevel level: Int) -> Int {
        min(max(100 - level, 0), 100)
    }

    public static func breakdown(_ pages: VMPages) -> MemoryBreakdown {
        let appPages = pages.internalPages >= pages.purgeablePages ? pages.internalPages - pages.purgeablePages : 0
        return MemoryBreakdown(
            app: appPages * pages.pageSize,
            wired: pages.wiredPages * pages.pageSize,
            compressed: pages.compressorPages * pages.pageSize,
            cached: (pages.externalPages + pages.purgeablePages) * pages.pageSize
        )
    }
}
