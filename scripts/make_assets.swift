// 生成应用图标（iconset）与示例图片 sample.png，供 build_app.sh 使用。
// 用法：swift scripts/make_assets.swift
import AppKit
import CoreText

let fm = FileManager.default
let dist = URL(fileURLWithPath: "dist", isDirectory: true)
let iconset = dist.appendingPathComponent("Markdown.iconset", isDirectory: true)
try? fm.createDirectory(at: dist, withIntermediateDirectories: true)
try? fm.createDirectory(at: iconset, withIntermediateDirectories: true)

func renderPNG(size: CGFloat, draw: () -> Void) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// A single frosted tile and a bold Markdown monogram, legible at Dock sizes.
func iconImage(size: CGFloat) -> Data {
    renderPNG(size: size) {
        let tile = NSBezierPath(roundedRect: NSRect(x: size * 0.08, y: size * 0.08, width: size * 0.84, height: size * 0.84),
                                xRadius: size * 0.19, yRadius: size * 0.19)
        NSGraphicsContext.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.24)
        shadow.shadowBlurRadius = size * 0.035
        shadow.shadowOffset = NSSize(width: 0, height: -size * 0.018)
        shadow.set()
        NSGradient(colors: [
            NSColor(calibratedRed: 0.09, green: 0.22, blue: 0.42, alpha: 0.96),
            NSColor(calibratedRed: 0.18, green: 0.49, blue: 0.68, alpha: 0.91),
            NSColor(calibratedRed: 0.66, green: 0.88, blue: 0.94, alpha: 0.86)
        ])!.draw(in: tile, angle: 65)
        NSGraphicsContext.restoreGraphicsState()
        NSGraphicsContext.saveGraphicsState()
        tile.addClip()
        NSGradient(starting: NSColor.white.withAlphaComponent(0.14), ending: .clear)!
            .draw(in: NSRect(x: 0, y: size * 0.48, width: size, height: size * 0.44), angle: -90)
        NSGraphicsContext.restoreGraphicsState()
        NSColor.white.withAlphaComponent(0.60).setStroke()
        tile.lineWidth = max(0.6, size * 0.009)
        tile.stroke()
        // Native system lettering, optically centered by its actual glyph bounds.
        let font = NSFont.systemFont(ofSize: size * 0.36, weight: .semibold)
        let lettering = NSAttributedString(string: "MD", attributes: [
            .font: font,
            .kern: -size * 0.012,
            .foregroundColor: NSColor.white.withAlphaComponent(0.96)
        ])
        let line = CTLineCreateWithAttributedString(lettering)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let context = NSGraphicsContext.current!.cgContext
        context.textPosition = CGPoint(x: (size - bounds.width) / 2 - bounds.minX,
                                       y: (size - bounds.height) / 2 - bounds.minY)
        CTLineDraw(line, context)
    }
}

// 示例图片（渐变 + 文字说明），供相对路径图片测试使用。
func sampleImage() -> Data {
    let w = 640, h = 360
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(x: 0, y: 0, width: w, height: h)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.10, green: 0.42, blue: 0.85, alpha: 1),
        NSColor(calibratedRed: 0.85, green: 0.24, blue: 0.55, alpha: 1)
    ])!.draw(in: rect, angle: -45)
    let para = NSMutableParagraphStyle()
    para.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 44),
        .foregroundColor: NSColor.white,
        .paragraphStyle: para
    ]
    ("Markdown 图片示例" as NSString).draw(in: NSRect(x: 0, y: h / 2 - 40, width: w, height: 80), withAttributes: attrs)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

// 输出 iconset（1x 与 2x）
let sizes: [(name: String, px: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]
for s in sizes {
    let data = iconImage(size: s.px)
    try! data.write(to: iconset.appendingPathComponent(s.name + ".png"))
}

let sample = sampleImage()
try! sample.write(to: dist.appendingPathComponent("sample.png"))

print("已生成 iconset (\(sizes.count) 张) 与 dist/sample.png")