import CoreGraphics

/// Screen-space geometry for a dropdown panel, in AppKit coordinates (origin bottom-left, y up).
public enum PanelPlacement {
    public static let gap: CGFloat = 4
    public static let margin: CGFloat = 8

    public static func frame(anchor: CGRect, size: CGSize, visibleFrame: CGRect) -> CGRect {
        let top = (min(anchor.minY, visibleFrame.maxY) - gap).rounded(.down)
        let leftmost = visibleFrame.minX + margin
        let rightmost = max(visibleFrame.maxX - margin - size.width, leftmost)
        let x = min(max(anchor.midX - size.width / 2, leftmost), rightmost).rounded()
        return CGRect(x: x, y: top - size.height, width: size.width, height: size.height)
    }

    /// Every display has its own copy of a menu bar item, so only a frame on the clicked screen is a valid anchor.
    public static func anchor(itemFrames: [CGRect], pointer: CGPoint, screenFrame: CGRect) -> CGRect {
        itemFrames.first { screenFrame.contains(CGPoint(x: $0.midX, y: $0.midY)) }
            ?? CGRect(x: pointer.x, y: screenFrame.maxY, width: 0, height: 0)
    }
}
