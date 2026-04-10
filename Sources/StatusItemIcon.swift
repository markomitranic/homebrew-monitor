import AppKit

func drawStatusIcon(runningCount: Int) -> NSImage {
    let w: CGFloat = 22
    let h: CGFloat = 22
    let image = NSImage(size: NSSize(width: w, height: h), flipped: false) { rect in

        // Database cylinder stack icon
        let cylWidth: CGFloat = 12
        let cylX: CGFloat = (w - cylWidth) / 2
        let ellipseHeight: CGFloat = 4
        let segmentHeight: CGFloat = 5

        // Three segments stacked vertically, centered
        let bottomY: CGFloat = 4.0
        let midY: CGFloat = bottomY + segmentHeight
        let topY: CGFloat = midY + segmentHeight

        NSColor.black.setStroke()
        let lineWidth: CGFloat = 1.3

        // Draw the three ellipse tops
        for y in [bottomY, midY, topY] {
            let ellipse = NSBezierPath(ovalIn: NSRect(
                x: cylX, y: y - ellipseHeight / 2,
                width: cylWidth, height: ellipseHeight
            ))
            ellipse.lineWidth = lineWidth
            ellipse.stroke()
        }

        // Draw vertical sides connecting bottom to top
        let sidePath = NSBezierPath()
        sidePath.lineWidth = lineWidth
        // Left side
        sidePath.move(to: NSPoint(x: cylX, y: bottomY))
        sidePath.line(to: NSPoint(x: cylX, y: topY))
        // Right side
        sidePath.move(to: NSPoint(x: cylX + cylWidth, y: bottomY))
        sidePath.line(to: NSPoint(x: cylX + cylWidth, y: topY))
        sidePath.stroke()

        // Top cap ellipse (filled to close the top)
        let topCap = NSBezierPath(ovalIn: NSRect(
            x: cylX, y: topY - ellipseHeight / 2,
            width: cylWidth, height: ellipseHeight
        ))
        topCap.lineWidth = lineWidth
        NSColor.black.setFill()
        topCap.fill()
        topCap.stroke()

        // Badge with running count
        if runningCount > 0 {
            let badgeRadius: CGFloat = 5.5
            let badgeCenterX: CGFloat = w - badgeRadius
            let badgeCenterY: CGFloat = badgeRadius - 0.5

            // Badge circle
            let badgeRect = NSRect(
                x: badgeCenterX - badgeRadius,
                y: badgeCenterY - badgeRadius,
                width: badgeRadius * 2,
                height: badgeRadius * 2
            )
            let badge = NSBezierPath(ovalIn: badgeRect)
            NSColor.black.setFill()
            badge.fill()

            // Number inside badge - draw in white (becomes transparent in template mode)
            let countStr = runningCount > 9 ? "+" : "\(runningCount)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 7.5),
                .foregroundColor: NSColor.white,
            ]
            let size = (countStr as NSString).size(withAttributes: attrs)
            let textPoint = NSPoint(
                x: badgeCenterX - size.width / 2,
                y: badgeCenterY - size.height / 2
            )
            (countStr as NSString).draw(at: textPoint, withAttributes: attrs)
        }

        return true
    }
    image.isTemplate = true
    return image
}
