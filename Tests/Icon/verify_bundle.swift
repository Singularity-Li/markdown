import AppKit
import CryptoKit

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let bundle = Bundle(url: url),
      let name = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String,
      let iconURL = bundle.url(forResource: name, withExtension: "icns"),
      let data = try? Data(contentsOf: iconURL), NSImage(data: data) != nil else {
    fatalError("App 必须包含有效且可解码的图标")
}
let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
guard name == "AppIcon-\(digest)" else {
    print("FAIL: 图标文件名必须包含实际内容指纹，避免沿用旧资源标识")
    exit(1)
}
guard let version = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
      let number = Int(version), number > 3 else {
    print("FAIL: 构建号必须高于旧版本 3")
    exit(1)
}
print("PASS: 交付 App 图标可解码、内容指纹匹配、构建号已更新")

// 检查实际交付 ICNS 在不同显示尺寸的底板、透明留白与双色字标。
let image = NSImage(data: data)!
for size in [16, 32, 64, 128, 256, 512, 1024] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current!.cgContext.clear(CGRect(x: 0, y: 0, width: size, height: size))
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    for fraction in [0.2, 0.25, 0.75, 0.8] {
        let color = bitmap.colorAt(x: size / 2, y: Int(Double(size) * fraction))!.usingColorSpace(.sRGB)!
        guard color.alphaComponent > 0.99, color.redComponent > 0.70,
              abs(color.redComponent - color.blueComponent) < 0.04 else {
            fatalError("图标底板必须是不透明浅灰色：\(size)px")
        }
    }
    guard bitmap.colorAt(x: 0, y: 0)!.alphaComponent < 0.01 else {
        fatalError("圆角底板外侧必须保留透明留白")
    }
    var blue = 0, red = 0
    for y in size / 4..<size * 3 / 4 {
        for x in size / 4..<size * 3 / 4 {
            let color = bitmap.colorAt(x: x, y: y)!.usingColorSpace(.sRGB)!
            guard color.alphaComponent > 0.99 else { fatalError("底板内部不得透明") }
            if color.blueComponent - color.redComponent > 0.1 { blue += 1 }
            if color.redComponent - color.blueComponent > 0.2 { red += 1 }
        }
    }
    guard blue > 0, red > 0 else { fatalError("必须保留深蓝 M 与酒红 D") }
}
print("PASS: 实际 ICNS 各尺寸具有不透明浅灰底板、透明外侧和双色字标")
