/// Which menu bar items macOS has been asked to place, and under which generation of names.
public struct ItemLayout: Sendable, Equatable {
    public var generation: Int
    public var placed: [String]

    public init(generation: Int = 0, placed: [String] = []) {
        self.generation = generation
        self.placed = placed
    }

    /// macOS 27 keeps the slot of every item name it has seen and puts a new name at the far end of them. Renaming
    /// every item makes it lay the whole group out again, in creation order.
    public func placing(_ items: [String]) -> ItemLayout {
        guard !Set(items).isSubset(of: placed) else { return self }
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
