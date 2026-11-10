/// The menu bar items macOS has been asked to place, left to right, and under which generation of names.
public struct ItemLayout: Sendable, Equatable {
    public var generation: Int
    public var placed: [String]

    public init(generation: Int = 0, placed: [String] = []) {
        self.generation = generation
        self.placed = placed
    }

    /// On macOS 27 an item added beside already-placed siblings landed at the far end of them and stayed there.
    /// With new names for every item, macOS laid the whole group out again in creation order.
    public func placing(_ items: [String]) -> ItemLayout {
        guard items != placed else { return self }
        return ItemLayout(generation: generation + 1, placed: items)
    }

    public func autosaveName(prefix: String, item: String) -> String {
        generation == 0 ? "\(prefix).\(item)" : "\(prefix).\(item).\(generation)"
    }

    /// macOS 26 puts an item that appears after its siblings at the far end of them; re-creating all of them in
    /// order restores the order.
    public static func needsRebuild(shownBefore: Set<String>?, shownNow: Set<String>) -> Bool {
        guard let shownBefore else { return false }
        return !shownNow.isSubset(of: shownBefore)
    }
}

public enum ItemOrder {
    private static let separator: Character = ","

    /// The stored order without unknown or repeated names. An item it lacks goes right after the nearest item that
    /// precedes it in `defaults`.
    public static func resolve(stored: String, defaults: [String]) -> [String] {
        var order: [String] = []
        for item in stored.split(separator: separator).map(String.init)
        where defaults.contains(item) && !order.contains(item) {
            order.append(item)
        }
        for (index, item) in defaults.enumerated() where !order.contains(item) {
            let anchor = defaults.prefix(index).last(where: order.contains).flatMap(order.firstIndex(of:))
            order.insert(item, at: anchor.map { $0 + 1 } ?? 0)
        }
        return order
    }

    public static func stored(_ order: [String]) -> String {
        order.joined(separator: String(separator))
    }

    public static func moving(_ item: String, by offset: Int, in order: [String]) -> [String] {
        guard let index = order.firstIndex(of: item), order.indices.contains(index + offset) else { return order }
        var moved = order
        moved.swapAt(index, index + offset)
        return moved
    }
}
