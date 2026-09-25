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
