// 分析截图：输出色彩网格与亮度统计，用于判断 UI 是否真的渲染了内容。
import AppKit

for path in CommandLine.arguments.dropFirst() {
    guard let rep = NSBitmapImageRep(contentsOfFile: path) else {
        print("\(path): 无法读取")
        continue
    }
    let w = rep.pixelsWide, h = rep.pixelsHigh
    print("== \(path) [\(w)x\(h)] ==")
    print("-- 12x8 采样色块 (每格平均区域中心色) --")
    for gy in 0..<8 {
        var row: [String] = []
        for gx in 0..<12 {
            let x = gx * w / 12 + w / 24
            let y = gy * h / 8 + h / 16
            if let c = rep.colorAt(x: x, y: y) {
                row.append(String(format: "%03d,%03d,%03d",
                                  Int(c.redComponent * 255),
                                  Int(c.greenComponent * 255),
                                  Int(c.blueComponent * 255)))
            } else {
                row.append("  ?  ")
            }
        }
        print(row.joined(separator: " "))
    }
    var minL = 1.0, maxL = 0.0, sum = 0.0, sumSq = 0.0, n = 0.0
    var dark = 0
    for y in stride(from: 0, to: h, by: 6) {
        for x in stride(from: 0, to: w, by: 6) {
            if let c = rep.colorAt(x: x, y: y) {
                let l = 0.299 * c.redComponent + 0.587 * c.greenComponent + 0.114 * c.blueComponent
                minL = min(minL, l); maxL = max(maxL, l)
                sum += l; sumSq += l * l; n += 1
                if l < 0.45 { dark += 1 }
            }
        }
    }
    let mean = sum / n
    let std = (sumSq / n - mean * mean).squareRoot()
    print(String(format: "亮度: min=%.2f max=%.2f mean=%.2f std=%.2f 暗像素占比=%.1f%% 采样=%d",
                 minL, maxL, mean, std, Double(dark) / n * 100, Int(n)))
    print(std < 0.02 ? ">> 判定: 接近纯色(空白)" : ">> 判定: 存在结构化内容")
    print("")
}