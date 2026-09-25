import AppKit
import Sparkle

/// 用户点击安装后自动完成下载、验签及重启；退出仍经过 AppDelegate 的保存检查。
final class UpdateUserDriver: SPUStandardUserDriver {
    let retryPolicy = UpdateRetryPolicy()

    override func showUpdateFound(with appcastItem: SUAppcastItem, state: SPUUserUpdateState,
                                  reply: @escaping (SPUUserUpdateChoice) -> Void) {
        if !appcastItem.isInformationOnlyUpdate,
           retryPolicy.mayResume(version: appcastItem.versionString, url: appcastItem.fileURL) {
            reply(.install)
            return
        }
        retryPolicy.reset()
        super.showUpdateFound(with: appcastItem, state: state) { [weak self] choice in
            if choice == .install && !appcastItem.isInformationOnlyUpdate {
                self?.retryPolicy.approve(version: appcastItem.versionString, url: appcastItem.fileURL)
            }
            reply(choice)
        }
    }

    override func showDownloadDidStartExtractingUpdate() {
        retryPolicy.startedInstalling()
        super.showDownloadDidStartExtractingUpdate()
    }

    override func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        if retryPolicy.reserveRetry(for: error as NSError) {
            NSLog("Markdown 安装暂时失败，准备重试 %d/3：%@", retryPolicy.attempts, String(describing: error))
            acknowledgement()
        } else {
            let exhausted = retryPolicy.attempts >= 3
            retryPolicy.reset()
            let original = error as NSError
            var info = original.userInfo
            if exhausted {
                info[NSLocalizedRecoverySuggestionErrorKey] = "已自动重试 3 次，仍无法完成更新。请确认公司防护软件已放行，必要时联系管理员后再试。"
            }
            super.showUpdaterError(NSError(domain: original.domain, code: original.code, userInfo: info),
                                   acknowledgement: acknowledgement)
        }
    }

    override func showReady(toInstallAndRelaunch reply: @escaping (SPUUserUpdateChoice) -> Void) {
        retryPolicy.startedInstalling()
        reply(.install)
    }
}

final class AppUpdater: NSObject, NSMenuItemValidation, SPUUpdaterDelegate {
    static let shared = AppUpdater()
    private let driver = UpdateUserDriver(hostBundle: .main, delegate: nil)
    private lazy var updater = SPUUpdater(hostBundle: .main, applicationBundle: .main,
                                         userDriver: driver, delegate: self)
    private var startupError: Error?
    private var started = false
    private var retryWork: DispatchWorkItem?
    private var retryPanel: NSPanel?
    private var retryGeneration = 0
    private(set) var isRelaunchingForUpdate = false

    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        isRelaunchingForUpdate = true
    }

    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        isRelaunchingForUpdate = false
        guard let delay = driver.retryPolicy.pendingDelay else {
            driver.retryPolicy.reset()
            return
        }
        // 仅在旧流程清理完成后再启动，避免 canCheckForUpdates 尚未恢复。
        showRetryPanel(delay: delay)
        let generation = retryGeneration
        let work = DispatchWorkItem { [weak self] in self?.performRetry(generation: generation, remainingWaits: 30) }
        retryWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func showRetryPanel(delay: TimeInterval) {
        retryPanel?.close()
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 135),
                            styleMask: [.titled], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.title = "正在等待安装重试"
        let label = NSTextField(wrappingLabelWithString: "如果公司防护软件正在询问，请按公司要求选择允许。将在 \(Int(delay)) 秒后自动重试（\(driver.retryPolicy.attempts)/3）。")
        label.frame = NSRect(x: 20, y: 55, width: 360, height: 60)
        panel.contentView?.addSubview(label)
        let cancel = NSButton(title: "取消更新", target: self, action: #selector(cancelRetry))
        cancel.frame = NSRect(x: 270, y: 15, width: 110, height: 30)
        cancel.bezelStyle = .rounded
        panel.contentView?.addSubview(cancel)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        retryPanel = panel
    }

    @objc private func cancelRetry() {
        retryGeneration += 1
        retryWork?.cancel()
        retryWork = nil
        retryPanel?.close()
        retryPanel = nil
        driver.retryPolicy.reset()
    }

    private func performRetry(generation: Int, remainingWaits: Int) {
        guard generation == retryGeneration, driver.retryPolicy.pendingDelay != nil else { return }
        guard updater.canCheckForUpdates else {
            guard remainingWaits > 0 else {
                cancelRetry()
                let alert = NSAlert()
                alert.messageText = "暂时无法继续更新"
                alert.informativeText = "更新器仍在忙，请稍后从菜单检查更新。"
                alert.runModal()
                return
            }
            let work = DispatchWorkItem { [weak self] in
                self?.performRetry(generation: generation, remainingWaits: remainingWaits - 1)
            }
            retryWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: work)
            return
        }
        retryPanel?.close()
        retryPanel = nil
        retryWork = nil
        driver.retryPolicy.beginRetry()
        updater.checkForUpdates()
    }

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
        if let panel = retryPanel { panel.makeKeyAndOrderFront(nil); return }
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
