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

// 检查实际交付 ICNS，而不是仅检查生成源：字标之外必须没有底板。
let image = NSImage(data: data)!
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 256, pixelsHigh: 256,
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSGraphicsContext.current!.cgContext.clear(CGRect(x: 0, y: 0, width: 256, height: 256))
image.draw(in: NSRect(x: 0, y: 0, width: 256, height: 256))
NSGraphicsContext.restoreGraphicsState()
var visiblePixels = 0
for y in 0..<256 {
    for x in 0..<256 {
        let alpha = bitmap.colorAt(x: x, y: y)!.alphaComponent
        if alpha > 0.01 { visiblePixels += 1 }
        if (y < 55 || y > 200 || x < 30 || x > 225) && alpha > 0.01 {
            fatalError("图标字标外必须为纯透明背景，不得残留底板")
        }
    }
}
guard visiblePixels > 2000 else { fatalError("图标必须保留可见的 MD 字标") }
print("PASS: 实际 ICNS 字标可见且背景透明")
