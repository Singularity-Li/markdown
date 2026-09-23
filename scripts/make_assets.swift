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

// Native MD lettering on a fully transparent canvas.
func iconImage(size: CGFloat) -> Data {
    renderPNG(size: size) {
        NSGraphicsContext.current!.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
        // Native system lettering, optically centered by its actual glyph bounds.
        let font = NSFont.systemFont(ofSize: size * 0.48, weight: .bold)
        let lettering = NSMutableAttributedString(string: "MD", attributes: [
            .font: font,
            .kern: -size * 0.012,
            .foregroundColor: NSColor(srgbRed: 32.0 / 255, green: 59.0 / 255, blue: 91.0 / 255, alpha: 1)
        ])
        lettering.addAttribute(.foregroundColor,
                               value: NSColor(srgbRed: 166.0 / 255, green: 61.0 / 255, blue: 80.0 / 255, alpha: 1),
                               range: NSRange(location: 1, length: 1))
        let line = CTLineCreateWithAttributedString(lettering)
        let bounds = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
        let context = NSGraphicsContext.current!.cgContext
        // Scale actual glyph bounds to 85% of the canvas width at every resolution.
        let scale = size * 0.85 / bounds.width
        context.saveGState()
        context.translateBy(x: (size - bounds.width * scale) / 2,
                            y: (size - bounds.height * scale) / 2)
        context.scaleBy(x: scale, y: scale)
        context.textPosition = CGPoint(x: -bounds.minX, y: -bounds.minY)
        CTLineDraw(line, context)
        context.restoreGState()
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
