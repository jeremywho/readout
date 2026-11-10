import CoreGraphics

/// Screen-space frame for a dropdown panel, in AppKit coordinates (origin bottom-left, y up).
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
}
