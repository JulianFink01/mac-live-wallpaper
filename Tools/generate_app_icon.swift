import AppKit
import Foundation

struct IconSlot {
    let size: Int
    let scale: Int
    let filename: String

    var pixels: Int { size * scale }
}

let projectRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appIconDirectory = projectRoot
    .appendingPathComponent("LiveWallpaper/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
let menuBarIconDirectory = projectRoot
    .appendingPathComponent("LiveWallpaper/Assets.xcassets/MenuBarIcon.imageset", isDirectory: true)

let slots = [
    IconSlot(size: 16, scale: 1, filename: "AppIcon-16.png"),
    IconSlot(size: 16, scale: 2, filename: "AppIcon-16@2x.png"),
    IconSlot(size: 32, scale: 1, filename: "AppIcon-32.png"),
    IconSlot(size: 32, scale: 2, filename: "AppIcon-32@2x.png"),
    IconSlot(size: 128, scale: 1, filename: "AppIcon-128.png"),
    IconSlot(size: 128, scale: 2, filename: "AppIcon-128@2x.png"),
    IconSlot(size: 256, scale: 1, filename: "AppIcon-256.png"),
    IconSlot(size: 256, scale: 2, filename: "AppIcon-256@2x.png"),
    IconSlot(size: 512, scale: 1, filename: "AppIcon-512.png"),
    IconSlot(size: 512, scale: 2, filename: "AppIcon-512@2x.png")
]

try FileManager.default.createDirectory(at: appIconDirectory, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: menuBarIconDirectory, withIntermediateDirectories: true)

for slot in slots {
    let image = drawAppIcon(pixels: slot.pixels)
    try writePNG(image, to: appIconDirectory.appendingPathComponent(slot.filename))
}

try writePNG(drawMenuBarIcon(pixels: 18), to: menuBarIconDirectory.appendingPathComponent("MenuBarIcon.png"))
try writePNG(drawMenuBarIcon(pixels: 36), to: menuBarIconDirectory.appendingPathComponent("MenuBarIcon@2x.png"))

print("Generated LiveWallpaper app icons in \(appIconDirectory.path)")

func drawAppIcon(pixels: Int) -> NSBitmapImageRep {
    let bounds = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    return drawBitmap(pixels: pixels) {
        NSGraphicsContext.current?.imageInterpolation = .high

        let radius = CGFloat(pixels) * 0.225
        let outer = NSBezierPath(roundedRect: bounds.insetBy(dx: CGFloat(pixels) * 0.035, dy: CGFloat(pixels) * 0.035), xRadius: radius, yRadius: radius)
        NSColor(calibratedRed: 0.04, green: 0.06, blue: 0.10, alpha: 1).setFill()
        outer.fill()

        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.03, green: 0.15, blue: 0.22, alpha: 1),
            NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.20, alpha: 1),
            NSColor(calibratedRed: 0.15, green: 0.06, blue: 0.20, alpha: 1)
        ])!
        gradient.draw(in: outer, angle: 45)

        let horizonRect = bounds.insetBy(dx: CGFloat(pixels) * 0.09, dy: CGFloat(pixels) * 0.13)
        let horizon = NSBezierPath(roundedRect: horizonRect, xRadius: CGFloat(pixels) * 0.16, yRadius: CGFloat(pixels) * 0.16)
        NSColor(calibratedWhite: 1, alpha: 0.09).setStroke()
        horizon.lineWidth = max(1, CGFloat(pixels) * 0.014)
        horizon.stroke()

        for index in 0..<5 {
            let y = CGFloat(pixels) * (0.30 + CGFloat(index) * 0.09)
            let wave = NSBezierPath()
            wave.move(to: NSPoint(x: CGFloat(pixels) * 0.15, y: y))
            wave.curve(
                to: NSPoint(x: CGFloat(pixels) * 0.85, y: y + CGFloat(pixels) * 0.015),
                controlPoint1: NSPoint(x: CGFloat(pixels) * 0.33, y: y + CGFloat(pixels) * 0.065),
                controlPoint2: NSPoint(x: CGFloat(pixels) * 0.58, y: y - CGFloat(pixels) * 0.045)
            )
            NSColor(calibratedRed: 0.13, green: 0.86, blue: 0.84, alpha: 0.16).setStroke()
            wave.lineWidth = max(1, CGFloat(pixels) * 0.012)
            wave.stroke()
        }

        let playPath = NSBezierPath()
        playPath.move(to: NSPoint(x: CGFloat(pixels) * 0.40, y: CGFloat(pixels) * 0.34))
        playPath.line(to: NSPoint(x: CGFloat(pixels) * 0.40, y: CGFloat(pixels) * 0.66))
        playPath.line(to: NSPoint(x: CGFloat(pixels) * 0.68, y: CGFloat(pixels) * 0.50))
        playPath.close()

        NSColor(calibratedRed: 0.25, green: 0.98, blue: 0.90, alpha: 1).setFill()
        playPath.fill()

        NSColor(calibratedWhite: 1, alpha: 0.20).setStroke()
        playPath.lineWidth = max(1, CGFloat(pixels) * 0.01)
        playPath.stroke()

        let glossRect = NSRect(x: CGFloat(pixels) * 0.11, y: CGFloat(pixels) * 0.64, width: CGFloat(pixels) * 0.78, height: CGFloat(pixels) * 0.18)
        let gloss = NSBezierPath(roundedRect: glossRect, xRadius: CGFloat(pixels) * 0.10, yRadius: CGFloat(pixels) * 0.10)
        NSColor(calibratedWhite: 1, alpha: 0.08).setFill()
        gloss.fill()
    }
}

func drawMenuBarIcon(pixels: Int) -> NSBitmapImageRep {
    let p = CGFloat(pixels)
    return drawBitmap(pixels: pixels) {
        NSColor.white.setStroke()
        let frame = NSBezierPath(roundedRect: NSRect(x: p * 0.10, y: p * 0.18, width: p * 0.80, height: p * 0.60), xRadius: p * 0.10, yRadius: p * 0.10)
        frame.lineWidth = max(1.2, p * 0.09)
        frame.stroke()

        let play = NSBezierPath()
        play.move(to: NSPoint(x: p * 0.42, y: p * 0.35))
        play.line(to: NSPoint(x: p * 0.42, y: p * 0.65))
        play.line(to: NSPoint(x: p * 0.65, y: p * 0.50))
        play.close()
        NSColor.white.setFill()
        play.fill()
    }
}

func drawBitmap(pixels: Int, draw: () -> Void) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: .alphaFirst,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    bitmap.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    draw()
    NSGraphicsContext.restoreGraphicsState()

    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    try data.write(to: url, options: [.atomic])
}
