import Foundation

/// 仅重试用户已批准版本的安装故障，不重试下载、验签或主动取消。
final class UpdateRetryPolicy {
    private(set) var approvedVersion: String?
    private var approvedURL: URL?
    private(set) var attempts = 0
    private(set) var pendingDelay: TimeInterval?
    private(set) var resuming = false
    private var installationStarted = false

    func approve(version: String, url: URL?) {
        reset()
        approvedVersion = version
        approvedURL = url
    }

    func mayResume(version: String, url: URL?) -> Bool {
        resuming && approvedVersion == version && approvedURL == url && url != nil
    }

    func startedInstalling() { installationStarted = true }

    func reserveRetry(for error: NSError) -> Bool {
        guard approvedVersion != nil, installationStarted, pendingDelay == nil, attempts < 3,
              error.domain == "SUSparkleErrorDomain",
              [4000, 4003, 4005, 4010, 4012].contains(error.code) else { return false }
        // 外层安装错误也可能包装签名失败、用户取消或拒绝授权；这些不得重试。
        var current: NSError? = error
        var depth = 0
        while let value = current, depth < 16 {
            if value.domain == "SUSparkleErrorDomain",
               [3001, 3002, 4001, 4006, 4007, 4008, 4009].contains(value.code) { return false }
            if value.domain == NSCocoaErrorDomain && value.code == NSUserCancelledError { return false }
            if value.domain == NSOSStatusErrorDomain && value.code == -128 { return false }
            current = value.userInfo[NSUnderlyingErrorKey] as? NSError
            depth += 1
        }
        guard current == nil else { return false }
        attempts += 1
        pendingDelay = TimeInterval(attempts * 15)
        resuming = true
        return true
    }

    func beginRetry() { pendingDelay = nil; installationStarted = false }

    func reset() {
        approvedVersion = nil
        approvedURL = nil
        attempts = 0
        pendingDelay = nil
        resuming = false
        installationStarted = false
    }
}
