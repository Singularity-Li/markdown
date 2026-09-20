// 生成应用图标（iconset）与示例图片 sample.png，供 build_app.sh 使用。
// 用法：swift scripts/make_assets.swift
import AppKit

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

func drawDownArrow(size: CGFloat) {
    let b = size * 0.5
    let top = size * 0.30
    let bottom = size * 0.72
    let halfWidth = size * 0.20
    NSColor.white.setStroke()
    NSColor.white.setFill()
    // 竖杆
    let stem = NSBezierPath()
    stem.move(to: NSPoint(x: b, y: top))
    stem.line(to: NSPoint(x: b, y: bottom))
    stem.lineWidth = size * 0.10
    stem.lineCapStyle = .round
    stem.stroke()
    // 箭头三角形
    let head = NSBezierPath()
    head.move(to: NSPoint(x: b - halfWidth, y: size * 0.58))
    head.line(to: NSPoint(x: b, y: size * 0.78))
    head.line(to: NSPoint(x: b + halfWidth, y: size * 0.58))
    head.close()
    head.fill()
}

// 图标（渐变圆角底 + 白色向下箭头）
func iconImage(size: CGFloat) -> Data {
    renderPNG(size: size) {
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let path = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.06, dy: size * 0.06),
                                xRadius: size * 0.22, yRadius: size * 0.22)
        let g = NSGradient(colors: [
            NSColor(calibratedRed: 0.22, green: 0.56, blue: 1.00, alpha: 1),
            NSColor(calibratedRed: 0.55, green: 0.30, blue: 0.98, alpha: 1)
        ])!
        g.draw(in: path, angle: -60)
        drawDownArrow(size: size)
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