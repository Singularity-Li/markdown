import AppKit
import Sparkle

/// 用户点击安装后自动完成下载、验签及重启；退出仍经过 AppDelegate 的保存检查。
final class UpdateUserDriver: SPUStandardUserDriver {
    override func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        reply(.install)
    }
}

final class AppUpdater: NSObject, NSMenuItemValidation {
    static let shared = AppUpdater()
    private let driver = UpdateUserDriver(hostBundle: .main, delegate: nil)
    private lazy var updater = SPUUpdater(hostBundle: .main, applicationBundle: .main,
                                         userDriver: driver, delegate: nil)
    private var startupError: Error?
    private var started = false

    func start() {
        guard !started else { return }
        do {
            try updater.start()
            started = true
            // 必须紧接 start 调用，避免与 Sparkle 的定时检查互相干扰。
            if updater.automaticallyChecksForUpdates {
                updater.checkForUpdatesInBackground()
            }
        } catch {
            startupError = error
            NSLog("Markdown 更新器启动失败：%@", error.localizedDescription)
        }
    }

    @objc func checkForUpdates(_ sender: Any?) {
        if let error = startupError {
            let alert = NSAlert()
            alert.messageText = "无法检查更新"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        } else if started && updater.canCheckForUpdates {
            updater.checkForUpdates()
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        startupError != nil || (started && updater.canCheckForUpdates)
    }
}
