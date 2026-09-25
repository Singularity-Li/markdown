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

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError("FAIL: " + message) }
    print("PASS: " + message)
}
let packageURL = URL(string: "https://github.com/example/app/releases/download/v2/App.zip")!
let blocked = NSError(domain: SUSparkleErrorDomain, code: 4005)
let policy = UpdateRetryPolicy()
expect(!policy.reserveRetry(for: blocked), "用户未确认安装时不自动重试")
policy.approve(version: "20", url: packageURL)
expect(!policy.reserveRetry(for: blocked), "未进入安装阶段不自动重试")
for attempt in 1...3 {
    policy.startedInstalling()
    expect(policy.reserveRetry(for: blocked), "第 \(attempt) 次安装被拦截后可重试")
    expect(policy.pendingDelay == Double(attempt * 15), "递增等待时间给用户放行机会")
    expect(!policy.reserveRetry(for: blocked), "重复错误回调不消耗额外重试次数")
    expect(policy.mayResume(version: "20", url: packageURL), "同一已确认更新免重复确认")
    expect(!policy.mayResume(version: "21", url: packageURL), "不自动安装未经确认的新版本")
    expect(!policy.mayResume(version: "20", url: URL(string: "https://example.com/other.zip")), "更新下载地址变化须重新确认")
    policy.beginRetry()
}
policy.startedInstalling()
expect(!policy.reserveRetry(for: blocked), "最多三次重试，不无限循环")
policy.reset()
expect(!policy.mayResume(version: "20", url: packageURL), "取消清除自动安装授权")
for code in [1002, 2001, 3000, 3001, 3002, 4001, 4006, 4007, 4008, 4009] {
    policy.approve(version: "20", url: packageURL)
    policy.startedInstalling()
    expect(!policy.reserveRetry(for: NSError(domain: SUSparkleErrorDomain, code: code)), "不重试非暂时安装错误 \(code)")
}
for cause in [NSError(domain: SUSparkleErrorDomain, code: 3001),
              NSError(domain: SUSparkleErrorDomain, code: 4007),
              NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError)] {
    policy.approve(version: "20", url: packageURL)
    policy.startedInstalling()
    let wrapped = NSError(domain: SUSparkleErrorDomain, code: 4005, userInfo: [NSUnderlyingErrorKey: cause])
    expect(!policy.reserveRetry(for: wrapped), "包装后的签名错误或主动取消仍不能重试")
}
for code in [4000, 4003, 4010, 4012] {
    policy.approve(version: "20", url: packageURL)
    policy.startedInstalling()
    expect(policy.reserveRetry(for: NSError(domain: SUSparkleErrorDomain, code: code)), "支持安装阻断错误 \(code)")
}
driver.retryPolicy.approve(version: "20", url: packageURL)
driver.retryPolicy.startedInstalling()
var acknowledgements = 0
driver.showUpdaterError(blocked) { acknowledgements += 1 }
expect(acknowledgements == 1 && driver.retryPolicy.pendingDelay == 15,
       "真实 Sparkle 驱动确认失败并预留重试，避免立即弹出终止错误")
