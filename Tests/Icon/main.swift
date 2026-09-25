import Foundation

let suite = "Markdown.IconTests.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
var failures = 0
var calls = 0
var status: Int32 = 0
var receivedURL: URL?
func check(_ title: String, _ passed: Bool) {
    print("\(passed ? "PASS" : "FAIL"): \(title)")
    if !passed { failures += 1 }
}
func refresh(_ path: String = "/Applications/Markdown.app", _ version: String = "4", _ icon: String = "AppIcon-a") {
    AppIconRefresh.registerIfNeeded(url: URL(fileURLWithPath: path), version: version,
                                   iconName: icon, defaults: defaults) { url in
        calls += 1
        receivedURL = url
        return status
    }
}
refresh()
check("首次启动注册当前安装位置", calls == 1 && receivedURL?.path == "/Applications/Markdown.app")
refresh()
check("未变化的安装不重复注册", calls == 1)
refresh("/Applications/Markdown.app", "5")
check("版本升级重新注册", calls == 2)
refresh("/Applications/Markdown.app", "5", "AppIcon-b")
check("图标变化重新注册", calls == 3)
refresh("/Users/Shared/Markdown.app", "5", "AppIcon-b")
check("移动安装位置重新注册", calls == 4 && receivedURL?.path == "/Users/Shared/Markdown.app")
status = -50
refresh("/Users/Shared/Markdown.app", "6", "AppIcon-b")
status = 0
refresh("/Users/Shared/Markdown.app", "6", "AppIcon-b")
check("注册失败后下次启动重试", calls == 6)
refresh("/Users/Shared/Markdown.app", "6", "AppIcon-b")
check("重试成功后停止重复注册", calls == 6)
exit(failures == 0 ? 0 : 1)
