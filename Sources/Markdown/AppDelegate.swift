import AppKit
import SwiftUI

/// 应用与窗口生命周期代理（手动实例化，见 main.swift）。
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DocumentStore.shared.confirmReplacement = { [weak self] in self?.confirmDiscardOrSave() ?? false }
        buildWindow()
        NSApp.activate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        confirmDiscardOrSave() ? .terminateNow : .terminateCancel
    }

    // 双击文件 / 拖到 Dock 图标 / `open -a Markdown <路径>` 都会触发（odoc 事件）。
    func application(_ application: NSApplication, openFiles filenames: [String]) {
        for name in filenames {
            DocumentStore.shared.handleOpen(URL(fileURLWithPath: name))
        }
        application.reply(toOpenOrPrint: .success)
    }

    // 部分场景会走 URL 形式。
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { DocumentStore.shared.handleOpen(url) }
    }

    // 点红色关闭按钮时，若有未保存内容则先提醒。
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard confirmDiscardOrSave() else { return false }
        // 关闭最后窗口随后触发退出，避免重复询问。
        DocumentStore.shared.isDirty = false
        return true
    }

    // MARK: - 窗口

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
        glass.translatesAutoresizingMaskIntoConstraints = false
        backdrop.addSubview(glass)
        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor),
            glass.topAnchor.constraint(equalTo: backdrop.topAnchor),
            glass.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor)
        ])
        win.contentView = backdrop

        win.center()
        win.makeKeyAndOrderFront(nil)
        window = win
    }

    private func confirmDiscardOrSave() -> Bool {
        let store = DocumentStore.shared
        guard store.isDirty else { return true }

        let alert = NSAlert()
        alert.messageText = "要保存更改吗？"
        alert.informativeText = "“\(store.currentURL?.lastPathComponent ?? "未命名")” 有未保存的更改。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "保存")
        alert.addButton(withTitle: "不保存")
        alert.addButton(withTitle: "取消")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            return store.save()
        case .alertSecondButtonReturn:
            return true
        default:
            return false
        }
    }
}