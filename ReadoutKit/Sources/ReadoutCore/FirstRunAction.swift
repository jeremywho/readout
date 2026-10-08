public struct FirstRunAction {
    private let isDone: () -> Bool
    private let markDone: () -> Void

    public init(isDone: @escaping () -> Bool, markDone: @escaping () -> Void) {
        self.isDone = isDone
        self.markDone = markDone
    }

    public func perform(_ body: () throws -> Void) {
        guard !isDone() else { return }
        markDone()
        try? body()
    }
}
