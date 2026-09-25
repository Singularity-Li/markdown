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
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                if abs(color.redComponent - 166.0 / 255) < 0.04 && abs(color.greenComponent - 61.0 / 255) < 0.04 && abs(color.blueComponent - 80.0 / 255) < 0.04 {
                    colored[x < bitmap.pixelsWide / 2 ? 0 : 1] += 1
                }
            }
        }
        if colored[selected] < 200 || colored[1-selected] > 10 {
            failures += 1
            print("FAIL: \(appearanceName.rawValue) 选中 \(selected) 的实际主题色像素 \(colored)")
        } else { print("PASS: \(appearanceName.rawValue) 选中 \(selected) 显示主题色且不污染未选中块") }
    }
}
exit(failures == 0 ? 0 : 1)
