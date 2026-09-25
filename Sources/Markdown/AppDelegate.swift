import AppKit
import SwiftUI

/// 应用与窗口生命周期代理（手动实例化，见 main.swift）。
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private let appearance = AppearanceSettings.shared
    private var didApproveWindowClose = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        AppIconRefresh.refresh()
        DocumentStore.shared.confirmClose = { [weak self] document in self?.closeDecision(for: document) ?? .cancel }
        DocumentStore.shared.chooseSaveURL = { OpenPanelHelper.savePanel(for: $0) }
        DocumentStore.shared.restoreUpdateSession()
        buildWindow()
        NSApp.activate()
        AppUpdater.shared.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if AppUpdater.shared.isRelaunchingForUpdate {
            if DocumentStore.shared.prepareUpdateRestart(alreadyApproved: didApproveWindowClose) {
                return .terminateNow
            }
            // Sparkle 同一安装流程重试退出时不会再次发出 willRelaunch 回调。
            return .terminateCancel
        }
        return (didApproveWindowClose || DocumentStore.shared.canCloseAll()) ? .terminateNow : .terminateCancel
    }

    // 双击文件 / 拖到 Dock 图标 / `open -a Markdown <路径>` 都会触发（odoc 事件）。
    func application(_ application: NSApplication, openFiles filenames: [String]) {
        DocumentStore.shared.handleOpen(filenames.map { URL(fileURLWithPath: $0) })
        application.reply(toOpenOrPrint: .success)
    }

    // 部分场景会走 URL 形式。
    func application(_ application: NSApplication, open urls: [URL]) {
        DocumentStore.shared.handleOpen(urls)
    }

    // 点红色关闭按钮时，若有未保存内容则先提醒。
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard DocumentStore.shared.canCloseAll() else { return false }
        // 关闭最后窗口随后触发退出，避免重复询问。
        didApproveWindowClose = true
        return true
    }

    // MARK: - 窗口

    func windowDidEnterFullScreen(_ notification: Notification) {
        DocumentStore.shared.isWindowFullScreen = true
    }

    func windowDidExitFullScreen(_ notification: Notification) {
        DocumentStore.shared.isWindowFullScreen = false
    }

    private func buildWindow() {
        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1160, height: 780),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.title = "Markdown"
        win.titlebarAppearsTransparent = true
        win.titleVisibility = .hidden
        win.isMovableByWindowBackground = true
        win.minSize = NSSize(width: 820, height: 560)
        // 单一玻璃承载整个窗口，内容层保持透明。
        win.isOpaque = false
        win.backgroundColor = .clear
        win.delegate = self

        let hosting = NSHostingController(rootView: ContentView(store: .shared))
        let glass = NSGlassEffectView()
        glass.style = .clear
        glass.cornerRadius = 12
        glass.contentView = hosting.view
        let backdrop = NSVisualEffectView()
        backdrop.material = .underWindowBackground
        backdrop.blendingMode = .behindWindow
        backdrop.state = .active
        // 模糊层与玻璃内容是同级视图，调节背景不会淡化文字或按钮。
        let container = NSView()
        for view in [backdrop, glass] {
            view.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                view.topAnchor.constraint(equalTo: container.topAnchor),
                view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
        }
        win.contentView = container
        appearance.onChange = { [weak win, weak backdrop, weak glass] value in
            win?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(1 - value)
            backdrop?.alphaValue = 1 - value * 0.85
            glass?.tintColor = NSColor.windowBackgroundColor.withAlphaComponent((1 - value) * 0.12)
        }
        appearance.onChange?(appearance.transparency)

        win.center()
        win.makeKeyAndOrderFront(nil)
        window = win
    }

    private func closeDecision(for document: OpenDocument) -> CloseDecision {
        let alert = NSAlert()
        alert.messageText = "要保存更改吗？"
        alert.informativeText = "“\(document.displayName)” 有未保存的更改。\n\(document.url?.deletingLastPathComponent().path ?? "尚未保存到文件")"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "不保存")
        alert.addButton(withTitle: "取消")
        switch alert.runModal() {
        case .alertFirstButtonReturn: return .save
        case .alertSecondButtonReturn: return .discard
        default: return .cancel
        }
    }
}
