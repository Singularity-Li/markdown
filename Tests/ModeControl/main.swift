import AppKit
let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
var failures = 0
for appearanceName in [NSAppearance.Name.aqua, .darkAqua] {
    for selected in [0, 1] {
        let control = ModeSegmentedControl(labels: ["编辑", "预览"], trackingMode: .selectOne, target: nil, action: nil)
        control.frame = NSRect(x: 0, y: 0, width: 104, height: 28)
        control.appearance = NSAppearance(named: appearanceName)
        control.selectedSegment = selected
        let bitmap = control.bitmapImageRepForCachingDisplay(in: control.bounds)!
        control.cacheDisplay(in: control.bounds, to: bitmap)
        var colored = [0, 0]
        var coloredRows = Set<Int>()
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                if abs(color.redComponent - 166.0 / 255) < 0.04 && abs(color.greenComponent - 61.0 / 255) < 0.04 && abs(color.blueComponent - 80.0 / 255) < 0.04 {
                    colored[x < bitmap.pixelsWide / 2 ? 0 : 1] += 1
                    coloredRows.insert(y)
                }
            }
        }
        if coloredRows.count != bitmap.pixelsHigh {
            failures += 1
            print("FAIL: 选中块应填满 28 点高度，实际覆盖 \(coloredRows.count)/\(bitmap.pixelsHigh) 像素行")
        } else { print("PASS: 选中块填满控件高度，与工具栏按钮及标签等高") }
        if colored[selected] < 200 || colored[1-selected] > 10 {
            failures += 1
            print("FAIL: \(appearanceName.rawValue) 选中 \(selected) 的实际主题色像素 \(colored)")
        } else { print("PASS: \(appearanceName.rawValue) 选中 \(selected) 显示主题色且不污染未选中块") }
    }
}
let animated = ModeSegmentedControl(labels: ["编辑", "预览"], trackingMode: .selectOne, target: nil, action: nil)
func checkAnimation(_ condition: Bool, _ message: String) {
    if condition { print("PASS: " + message) }
    else { failures += 1; print("FAIL: " + message) }
}
animated.setModeSelection(0, animated: true)
checkAnimation(animated.highlightPosition == 0, "首次显示直接定位，不播放无意义动画")
animated.setModeSelection(1, animated: true)
RunLoop.current.run(until: Date().addingTimeInterval(0.10))
checkAnimation(animated.highlightPosition > 0 && animated.highlightPosition < 1, "切换时存在连续中间位置，不瞬移")
let interruptedPosition = animated.highlightPosition
animated.setModeSelection(0, animated: true)
checkAnimation(abs(animated.highlightPosition - interruptedPosition) < 0.1, "快速反向切换从当前位置继续，不跳回端点")
RunLoop.current.run(until: Date().addingTimeInterval(0.4))
checkAnimation(abs(animated.highlightPosition) < 0.001 && animated.selectedSegment == 0, "动画完成后与最新选择一致")
animated.setModeSelection(1, animated: false)
checkAnimation(animated.highlightPosition == 1, "减少动态效果时立即完成切换")
exit(failures == 0 ? 0 : 1)
