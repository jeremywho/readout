import CoreGraphics
import Testing

@testable import ReadoutCore

@Suite struct PanelPlacementTests {
    private let visible = CGRect(x: 0, y: 91, width: 1920, height: 959)
    private let menuBarItem = CGRect(x: 1229, y: 1050, width: 82, height: 30)
    private let size = CGSize(width: 348, height: 366)

    @Test func hangsBelowTheMenuBarCenteredOnItsItem() {
        let frame = PanelPlacement.frame(anchor: menuBarItem, size: size, visibleFrame: visible)
        #expect(frame.maxY == visible.maxY - PanelPlacement.gap)
        #expect(frame.midX == menuBarItem.midX)
        #expect(frame.size == size)
    }

    @Test func neverCoversTheMenuBarWhenTheAnchorReportsItselfInsideIt() {
        let inset = CGRect(x: 1229, y: 1062, width: 82, height: 18)
        let frame = PanelPlacement.frame(anchor: inset, size: size, visibleFrame: visible)
        #expect(frame.maxY <= visible.maxY)
    }

    @Test func followsAnAnchorThatSitsBelowTheMenuBar() {
        let lowered = CGRect(x: 1229, y: 1000, width: 82, height: 30)
        let frame = PanelPlacement.frame(anchor: lowered, size: size, visibleFrame: visible)
        #expect(frame.maxY == 1000 - PanelPlacement.gap)
    }

    @Test func keepsItsTopEdgeWhenTheContentGrows() {
        let short = PanelPlacement.frame(anchor: menuBarItem, size: size, visibleFrame: visible)
        let tall = PanelPlacement.frame(
            anchor: menuBarItem, size: CGSize(width: size.width, height: size.height + 120), visibleFrame: visible)
        #expect(tall.maxY == short.maxY)
        #expect(tall.minY == short.minY - 120)
    }

    @Test func staysInsideTheRightEdgeOfTheScreen() {
        let clock = CGRect(x: 1880, y: 1050, width: 40, height: 30)
        let frame = PanelPlacement.frame(anchor: clock, size: size, visibleFrame: visible)
        #expect(frame.maxX == visible.maxX - PanelPlacement.margin)
    }

    @Test func staysInsideTheLeftEdgeOfTheScreen() {
        let apple = CGRect(x: 0, y: 1050, width: 40, height: 30)
        let frame = PanelPlacement.frame(anchor: apple, size: size, visibleFrame: visible)
        #expect(frame.minX == visible.minX + PanelPlacement.margin)
    }

    @Test func usesTheScreenTheItemIsOn() {
        let secondScreen = CGRect(x: 1920, y: 0, width: 2560, height: 1410)
        let item = CGRect(x: 3000, y: 1410, width: 82, height: 30)
        let frame = PanelPlacement.frame(anchor: item, size: size, visibleFrame: secondScreen)
        #expect(frame.midX == item.midX)
        #expect(frame.maxY == secondScreen.maxY - PanelPlacement.gap)
    }

    @Test func anchorsOnTheItemCopyThatIsOnTheClickedScreen() {
        let first = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let second = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let copy = CGRect(x: 3202, y: 1050, width: 82, height: 30)
        let pointer = CGPoint(x: 3250, y: 1070)
        #expect(PanelPlacement.anchor(itemFrames: [copy, menuBarItem], pointer: pointer, screenFrame: second) == copy)
        #expect(
            PanelPlacement.anchor(itemFrames: [copy, menuBarItem], pointer: pointer, screenFrame: first) == menuBarItem)
    }

    @Test func anchorsUnderThePointerWhenNoItemCopyIsOnTheClickedScreen() {
        let second = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let parked = CGRect(x: 3840, y: 1050, width: 82, height: 30)
        let anchor = PanelPlacement.anchor(
            itemFrames: [parked, menuBarItem], pointer: CGPoint(x: 3200, y: 1070), screenFrame: second)
        #expect(anchor.midX == 3200)
        #expect(anchor.minY == second.maxY)
        let frame = PanelPlacement.frame(
            anchor: anchor, size: size, visibleFrame: CGRect(x: 1920, y: 0, width: 1920, height: 1050))
        #expect(frame.maxY == 1050 - PanelPlacement.gap)
        #expect(frame.midX == 3200)
    }

    @Test func pinsToTheLeftMarginWhenThePanelIsWiderThanTheScreen() {
        let narrow = CGRect(x: 0, y: 0, width: 300, height: 600)
        let frame = PanelPlacement.frame(
            anchor: CGRect(x: 100, y: 600, width: 40, height: 30), size: size, visibleFrame: narrow)
        #expect(frame.minX == narrow.minX + PanelPlacement.margin)
    }
}
