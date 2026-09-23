import AppKit

/// 菜单动作的接收者。
@objc final class MenuRouter: NSObject {
    static let shared = MenuRouter()
    @objc func newDocument() { DocumentStore.shared.newDocument() }
    @objc func openFile() { OpenPanelHelper.openPanel() }
    @objc func closeTab() {
        if let id = DocumentStore.shared.activeID { DocumentStore.shared.close(id) }
        else { NSApp.keyWindow?.performClose(nil) }
    }
    @objc func save() { _ = DocumentStore.shared.save() }
    @objc func toggleMode() { DocumentStore.shared.isPreviewMode.toggle() }
}

/// 手工构建主菜单（含 Cmd+S 保存、Cmd+O 打开文件或文件夹）。
enum MainMenu {
    static func build() -> NSMenu {
        let main = NSMenu()

        // 应用菜单
        let appItem = NSMenuItem()
        appItem.title = "Markdown"
        main.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "关于 Markdown", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "隐藏 Markdown", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        let hideOthers = NSMenuItem(title: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "退出 Markdown", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // 文件菜单
        let fileItem = NSMenuItem()
        main.addItem(fileItem)
        let fileMenu = NSMenu(title: "文件")
        fileItem.submenu = fileMenu
        fileMenu.addItem(action(#selector(MenuRouter.newDocument), title: "新建", key: "n", modifiers: .command))
        fileMenu.addItem(action(#selector(MenuRouter.openFile), title: "打开…", key: "o", modifiers: .command))
        fileMenu.addItem(action(#selector(MenuRouter.closeTab), title: "关闭标签页", key: "w", modifiers: .command))
        fileMenu.addItem(.separator())
        fileMenu.addItem(action(#selector(MenuRouter.save), title: "保存", key: "s", modifiers: .command))

        // 编辑菜单（让 TextEditor 里复制粘贴等可用）
        let editItem = NSMenuItem()
        main.addItem(editItem)
        let editMenu = NSMenu(title: "编辑")
        editItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "撤销", action: NSSelectorFromString("undo:"), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "重做", action: NSSelectorFromString("redo:"), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "拷贝", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))

        // 显示菜单
        let viewItem = NSMenuItem()
        main.addItem(viewItem)
        let viewMenu = NSMenu(title: "显示")
        viewItem.submenu = viewMenu
        viewMenu.addItem(action(#selector(MenuRouter.toggleMode), title: "切换 预览/编辑", key: "p", modifiers: [.command, .shift]))

        // 窗口菜单
        let windowItem = NSMenuItem()
        main.addItem(windowItem)
        let windowMenu = NSMenu(title: "窗口")
        windowItem.submenu = windowMenu
        windowMenu.addItem(NSMenuItem(title: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m"))
        NSApp.windowsMenu = windowMenu

        return main
    }

    private static func action(_ sel: Selector, title: String, key: String, modifiers: NSEvent.ModifierFlags) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: sel, keyEquivalent: key)
        item.keyEquivalentModifierMask = modifiers
        item.target = MenuRouter.shared
        return item
    }
}