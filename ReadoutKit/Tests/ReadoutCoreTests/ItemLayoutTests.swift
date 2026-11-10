import Testing

@testable import ReadoutCore

@Suite struct ItemLayoutTests {
    private let five = ["temperature", "network", "disk", "cpu", "memory"]
    private let six = ["temperature", "network", "disk", "cpu", "gpu", "memory"]

    @Test func anInstallWithNoRecordStartsANewGeneration() {
        let layout = ItemLayout().placing(six)
        #expect(layout == ItemLayout(generation: 1, placed: six))
    }

    @Test func theSameItemsKeepTheirGenerationOnLaterLaunches() {
        let layout = ItemLayout(generation: 1, placed: six)
        #expect(layout.placing(six) == layout)
        #expect(layout.placing(six.reversed()) == layout)
    }

    @Test func anItemAddedByAnUpdateStartsANewGenerationOnce() {
        let updated = ItemLayout(generation: 1, placed: five).placing(six)
        #expect(updated == ItemLayout(generation: 2, placed: six))
        #expect(updated.placing(six) == updated)
    }

    @Test func anItemRemovedByAnUpdateKeepsTheGeneration() {
        let layout = ItemLayout(generation: 2, placed: six)
        #expect(layout.placing(five) == layout)
    }

    @Test func autosaveNamesChangeWithTheGeneration() {
        let prefix = "com.daughhetee.Readout"
        #expect(ItemLayout().autosaveName(prefix: prefix, item: "gpu") == "com.daughhetee.Readout.gpu")
        #expect(
            ItemLayout(generation: 2, placed: six).autosaveName(prefix: prefix, item: "gpu")
                == "com.daughhetee.Readout.gpu.2")
    }

    @Test func itemsAreRebuiltOnlyWhenOneAppearsAfterTheFirstPass() {
        #expect(!ItemLayout.needsRebuild(shownBefore: nil, shownNow: Set(six)))
        #expect(!ItemLayout.needsRebuild(shownBefore: Set(six), shownNow: Set(six)))
        #expect(!ItemLayout.needsRebuild(shownBefore: Set(six), shownNow: Set(five)))
        #expect(ItemLayout.needsRebuild(shownBefore: Set(five), shownNow: Set(six)))
        #expect(ItemLayout.needsRebuild(shownBefore: ["cpu", "gpu"], shownNow: ["cpu", "memory"]))
    }
}
