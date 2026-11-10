import AppKit
import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let iconSet = root.appendingPathComponent("AppIcon.appiconset")
let launchSet = root.appendingPathComponent("LaunchImage.imageset")

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> NSColor {
    NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1)
}

let midnight = color(0.051, 0.067, 0.09)
let electricBlue = color(0.18, 0.36, 0.83)
let aqua = color(0.26, 0.84, 0.71)
let amber = color(1, 0.78, 0.43)
let coral = color(1, 0.45, 0.41)
let bodyColor = color(0.94, 0.96, 0.99)

func drawMark(in rect: NSRect) {
    let graphics = NSGraphicsContext.current!.cgContext
    graphics.saveGState()
    graphics.clip(to: rect)
    let scaleX = rect.width / 1024
    let scaleY = rect.height / 1024
    graphics.translateBy(x: rect.minX, y: rect.minY)
    graphics.scaleBy(x: scaleX, y: scaleY)

    let body = NSBezierPath()
    body.move(to: NSPoint(x: 128, y: 424))
    body.line(to: NSPoint(x: 158, y: 500))
    body.curve(
        to: NSPoint(x: 252, y: 555),
        controlPoint1: NSPoint(x: 171, y: 538),
        controlPoint2: NSPoint(x: 204, y: 555)
    )
    body.line(to: NSPoint(x: 386, y: 555))
    body.line(to: NSPoint(x: 457, y: 687))
    body.curve(
        to: NSPoint(x: 522, y: 720),
        controlPoint1: NSPoint(x: 480, y: 714),
        controlPoint2: NSPoint(x: 496, y: 720)
    )
    body.line(to: NSPoint(x: 650, y: 720))
    body.curve(
        to: NSPoint(x: 710, y: 684),
        controlPoint1: NSPoint(x: 684, y: 720),
        controlPoint2: NSPoint(x: 701, y: 703)
    )
    body.line(to: NSPoint(x: 752, y: 559))
    body.line(to: NSPoint(x: 821, y: 545))
    body.curve(
        to: NSPoint(x: 890, y: 478),
        controlPoint1: NSPoint(x: 869, y: 538),
        controlPoint2: NSPoint(x: 886, y: 512)
    )
    body.line(to: NSPoint(x: 895, y: 432))
    body.close()
    bodyColor.setFill()
    body.fill()

    let rearWindow = NSBezierPath()
    rearWindow.move(to: NSPoint(x: 310, y: 580))
    rearWindow.line(to: NSPoint(x: 377, y: 660))
    rearWindow.line(to: NSPoint(x: 461, y: 660))
    rearWindow.line(to: NSPoint(x: 461, y: 580))
    rearWindow.close()
    midnight.setFill()
    rearWindow.fill()

    let frontWindow = NSBezierPath()
    frontWindow.move(to: NSPoint(x: 489, y: 580))
    frontWindow.line(to: NSPoint(x: 489, y: 660))
    frontWindow.line(to: NSPoint(x: 653, y: 660))
    frontWindow.line(to: NSPoint(x: 683, y: 580))
    frontWindow.close()
    frontWindow.fill()

    for centerX: CGFloat in [300, 714] {
        let tire = NSBezierPath(ovalIn: NSRect(x: centerX - 72, y: 352, width: 144, height: 144))
        midnight.setFill()
        tire.fill()
        let rim = NSBezierPath(ovalIn: NSRect(x: centerX - 36, y: 388, width: 72, height: 72))
        electricBlue.setFill()
        rim.fill()
        let hub = NSBezierPath(ovalIn: NSRect(x: centerX - 15, y: 409, width: 30, height: 30))
        aqua.setFill()
        hub.fill()
    }

    let tailLight = NSBezierPath(roundedRect: NSRect(x: 143, y: 445, width: 34, height: 20), xRadius: 8, yRadius: 8)
    coral.setFill()
    tailLight.fill()
    let headlight = NSBezierPath(roundedRect: NSRect(x: 851, y: 445, width: 34, height: 20), xRadius: 8, yRadius: 8)
    amber.setFill()
    headlight.fill()

    graphics.restoreGState()
}

func makeBitmap(width: Int, height: Int, launch: Bool = false) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: width,
        pixelsHigh: height,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high
    NSColor.clear.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

    if launch {
        midnight.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
        let markWidth = CGFloat(width) * 0.78
        let markHeight = markWidth * 0.72
        drawMark(
            in: NSRect(
                x: (CGFloat(width) - markWidth) / 2,
                y: CGFloat(height) * 0.42,
                width: markWidth,
                height: markHeight
            )
        )
        let title = NSAttributedString(
            string: "AUTOSPHERE",
            attributes: [
                .font: NSFont.systemFont(ofSize: CGFloat(width) * 0.075, weight: .semibold),
                .foregroundColor: bodyColor,
                .kern: CGFloat(width) * 0.012,
            ]
        )
        title.draw(at: NSPoint(x: (CGFloat(width) - title.size().width) / 2, y: CGFloat(height) * 0.18))
    } else {
        midnight.setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
        drawMark(in: NSRect(x: 0, y: 0, width: width, height: height))
    }

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

func writePNG(_ bitmap: NSBitmapImageRep, to url: URL) throws {
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "AutoSphereIcon", code: 1)
    }
    try data.write(to: url)
}

let iconJSON = try Data(contentsOf: iconSet.appendingPathComponent("Contents.json"))
let iconContents = try JSONSerialization.jsonObject(with: iconJSON) as! [String: Any]
let iconImages = iconContents["images"] as! [[String: Any]]
for entry in iconImages {
    guard
        let filename = entry["filename"] as? String,
        let pointSize = (entry["size"] as? String)?.split(separator: "x").first,
        let scaleText = entry["scale"] as? String,
        let points = Double(pointSize),
        let scale = Double(scaleText.dropLast())
    else { continue }
    let pixels = Int((points * scale).rounded())
    try writePNG(makeBitmap(width: pixels, height: pixels), to: iconSet.appendingPathComponent(filename))
}

let launchImages: [(String, Int, Int)] = [
    ("LaunchImage.png", 168, 185),
    ("LaunchImage@2x.png", 336, 370),
    ("LaunchImage@3x.png", 504, 555),
]
for (filename, width, height) in launchImages {
    try writePNG(makeBitmap(width: width, height: height, launch: true), to: launchSet.appendingPathComponent(filename))
}

print("Generated AutoSphere iOS icons and launch images.")