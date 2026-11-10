import Testing

@testable import ReadoutCore

@Suite struct ItemLayoutTests {
    private let five = ["temperature", "network", "disk", "cpu", "memory"]
    private let six = ["temperature", "network", "disk", "cpu", "gpu", "memory"]

    @Test func anInstallWithNoRecordStartsANewGeneration() {
        let layout = ItemLayout().placing(six)
        #expect(layout == ItemLayout(generation: 1, placed: six))
    }

    @Test func theSameItemsInTheSameOrderKeepTheirGenerationOnLaterLaunches() {
        let layout = ItemLayout(generation: 1, placed: six)
        #expect(layout.placing(six) == layout)
    }

    @Test func aNewOrderStartsANewGenerationOnce() {
        let reordered = Array(six.reversed())
        let layout = ItemLayout(generation: 1, placed: six).placing(reordered)
        #expect(layout == ItemLayout(generation: 2, placed: reordered))
        #expect(layout.placing(reordered) == layout)
    }

    @Test func anItemAddedByAnUpdateStartsANewGenerationOnce() {
        let updated = ItemLayout(generation: 1, placed: five).placing(six)
        #expect(updated == ItemLayout(generation: 2, placed: six))
        #expect(updated.placing(six) == updated)
    }

    @Test func anItemRemovedByAnUpdateStartsANewGeneration() {
        let layout = ItemLayout(generation: 2, placed: six).placing(five)
        #expect(layout == ItemLayout(generation: 3, placed: five))
    }

    @Test func autosaveNamesChangeWithTheGeneration() {
        let prefix = "com.daughhetee.Readout"
        #expect(ItemLayout().autosaveName(prefix: prefix, item: "gpu") == "com.daughhetee.Readout.gpu")
        #expect(
            ItemLayout(generation: 2, placed: six).autosaveName(prefix: prefix, item: "gpu")
                == "com.daughhetee.Readout.gpu.2")
    }

    @Test func anEmptyStoredOrderIsTheDefaultOrder() {
        #expect(ItemOrder.resolve(stored: "", defaults: six) == six)
    }

    @Test func aStoredOrderRoundTrips() {
        let order = ["memory", "gpu", "temperature", "cpu", "network", "disk"]
        #expect(ItemOrder.resolve(stored: ItemOrder.stored(order), defaults: six) == order)
    }

    @Test func unknownAndRepeatedNamesAreDropped() {
        let stored = "memory,bogus,memory,gpu,temperature,cpu,network,disk,gpu"
        #expect(
            ItemOrder.resolve(stored: stored, defaults: six)
                == ["memory", "gpu", "temperature", "cpu", "network", "disk"])
    }

    @Test func anItemMissingFromTheStoredOrderFollowsItsDefaultNeighbour() {
        #expect(
            ItemOrder.resolve(stored: "memory,cpu,disk,network,temperature", defaults: six)
                == ["memory", "cpu", "gpu", "disk", "network", "temperature"])
        #expect(
            ItemOrder.resolve(stored: "memory,gpu,cpu,disk,network", defaults: six)
                == ["temperature", "memory", "gpu", "cpu", "disk", "network"])
    }

    @Test func movingSwapsWithTheNeighbourAndStopsAtTheEnds() {
        #expect(ItemOrder.moving("gpu", by: -1, in: six) == ["temperature", "network", "disk", "gpu", "cpu", "memory"])
        #expect(ItemOrder.moving("gpu", by: 1, in: six) == ["temperature", "network", "disk", "cpu", "memory", "gpu"])
        #expect(ItemOrder.moving("temperature", by: -1, in: six) == six)
        #expect(ItemOrder.moving("memory", by: 1, in: six) == six)
        #expect(ItemOrder.moving("bogus", by: 1, in: six) == six)
    }

    @Test func itemsAreRebuiltOnlyWhenOneAppearsAfterTheFirstPass() {
        #expect(!ItemLayout.needsRebuild(shownBefore: nil, shownNow: Set(six)))
        #expect(!ItemLayout.needsRebuild(shownBefore: Set(six), shownNow: Set(six)))
        #expect(!ItemLayout.needsRebuild(shownBefore: Set(six), shownNow: Set(five)))
        #expect(ItemLayout.needsRebuild(shownBefore: Set(five), shownNow: Set(six)))
        #expect(ItemLayout.needsRebuild(shownBefore: ["cpu", "gpu"], shownNow: ["cpu", "memory"]))
    }
}
