import AppKit
import Sparkle

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
let bundle = Bundle(url: URL(fileURLWithPath: CommandLine.arguments[1]))!
let driver = UpdateUserDriver(hostBundle: bundle, delegate: nil)
var replies = 0
var choice: SPUUserUpdateChoice?
driver.showReady(toInstallAndRelaunch: {
    replies += 1
    choice = $0
})
guard replies == 1, choice == .install else {
    print("FAIL: 用户已确认更新且验签完成后，应继续安装，无需再次点击")
    exit(1)
}
print("PASS: 下载验证完成后自动进入安装重启流程")
