import SwiftUI

/// 使用原生分段控件交互，并显式绘制品牌选中块。
struct ReadingModeControl: NSViewRepresentable {
    @Binding var isPreview: Bool
    @Binding var isSource: Bool
    let isEnabled: Bool

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: ModeSegmentedControl, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 174, height: AppTheme.toolbarControlHeight)
    }

    func makeCoordinator() -> Coordinator { Coordinator(preview: $isPreview, source: $isSource) }

    func makeNSView(context: Context) -> ModeSegmentedControl {
        let control = ModeSegmentedControl(labels: ["源码", "可视化", "预览"], trackingMode: .selectOne,
                                         target: context.coordinator, action: #selector(Coordinator.selectMode(_:)))
        control.controlSize = .large
        control.segmentStyle = .rounded
        control.setAccessibilityLabel("阅读模式")
        return control
    }

    func updateNSView(_ control: ModeSegmentedControl, context: Context) {
        context.coordinator.preview = $isPreview
        context.coordinator.source = $isSource
        control.setModeSelection(isPreview ? 2 : (isSource ? 0 : 1),
                                 animated: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        control.isEnabled = isEnabled
        control.needsDisplay = true
    }

    final class Coordinator: NSObject {
        var preview: Binding<Bool>
        var source: Binding<Bool>
        init(preview: Binding<Bool>, source: Binding<Bool>) {
            self.preview = preview
            self.source = source
        }
        @objc func selectMode(_ sender: NSSegmentedControl) {
            if sender.selectedSegment != 2 { source.wrappedValue = sender.selectedSegment == 0 }
            preview.wrappedValue = sender.selectedSegment == 2
        }
    }
}
