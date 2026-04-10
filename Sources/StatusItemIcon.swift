import AppKit

func drawStatusIcon(active: Bool) -> NSImage {
    let w: CGFloat = 22
    let h: CGFloat = 22
    let image = NSImage(size: NSSize(width: w, height: h), flipped: false) { rect in
        NSColor.black.setStroke()
        NSColor.black.setFill()
        let lw: CGFloat = 1.4

        // Beer mug body
        let mugL: CGFloat = 3.5
        let mugB: CGFloat = 2
        let mugW: CGFloat = 11
        let mugH: CGFloat = 14
        let body = NSBezierPath(roundedRect: NSRect(x: mugL, y: mugB, width: mugW, height: mugH),
                                xRadius: 1.5, yRadius: 1.5)
        body.lineWidth = lw
        if active { body.fill() }
        body.stroke()

        // Handle (C-curve on the right)
        let handle = NSBezierPath()
        handle.lineWidth = lw
        handle.move(to: NSPoint(x: mugL + mugW, y: 13))
        handle.curve(to: NSPoint(x: mugL + mugW, y: 6),
                     controlPoint1: NSPoint(x: mugL + mugW + 4.5, y: 13),
                     controlPoint2: NSPoint(x: mugL + mugW + 4.5, y: 6))
        handle.stroke()

        // Foam bumps on top (only when full)
        if active {
            let foamY = mugB + mugH
            let foamH: CGFloat = 3.5
            let bw = mugW / 3.0
            let foam = NSBezierPath()
            foam.move(to: NSPoint(x: mugL, y: foamY))
            for i in 0..<3 {
                let sx = mugL + bw * CGFloat(i)
                let ex = sx + bw
                foam.curve(to: NSPoint(x: ex, y: foamY),
                           controlPoint1: NSPoint(x: sx, y: foamY + foamH),
                           controlPoint2: NSPoint(x: ex, y: foamY + foamH))
            }
            foam.close()
            foam.fill()
        }

        return true
    }
    image.isTemplate = true
    return image
}
