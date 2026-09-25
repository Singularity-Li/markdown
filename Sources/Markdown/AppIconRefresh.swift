import AppKit
import CoreServices

/// 只更新当前安装包的注册信息，不修改包内容或清理系统缓存。
enum AppIconRefresh {
    static func refresh() {
        let bundle = Bundle.main
        guard bundle.bundleURL.pathExtension == "app",
              let iconName = bundle.object(forInfoDictionaryKey: "CFBundleIconFile") as? String,
              let iconURL = bundle.url(forResource: iconName, withExtension: "icns"),
              let image = NSImage(contentsOf: iconURL) else { return }

        // 直接读取当前包，避免运行中的 Dock 图标沿用系统缓存。
        NSApp.applicationIconImage = image
        let version = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        registerIfNeeded(url: bundle.bundleURL, version: version, iconName: iconName,
                         defaults: .standard) { url in
            LSRegisterURL(url as CFURL, true)
        }
    }

    static func registerIfNeeded(url: URL, version: String, iconName: String,
                                 defaults: UserDefaults, register: (URL) -> OSStatus) {
        let key = "registeredAppIconIdentity"
        let identity = [url.standardizedFileURL.path, version, iconName]
        guard defaults.stringArray(forKey: key) != identity else { return }
        let status = register(url)
        if status == noErr {
            defaults.set(identity, forKey: key)
        } else {
            // 失败不记录成功标识，下次启动重试。
            NSLog("Markdown 图标注册更新失败：%d", status)
        }
    }
}
