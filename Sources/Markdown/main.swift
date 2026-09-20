import AppKit

// AppKit 引导入口（CLT 无 SwiftUIMacros 插件，改用手动 AppKit 生命周期）。
let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.setActivationPolicy(.regular)
app.mainMenu = MainMenu.build()
app.run()