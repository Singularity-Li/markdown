import SwiftUI

/// 使用原生分段控件交互，并显式绘制品牌选中块。
struct ReadingModeControl: NSViewRepresentable {
    @Binding var isPreview: Bool
    let isEnabled: Bool

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: ModeSegmentedControl, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 104, height: AppTheme.toolbarControlHeight)
    }

    func makeCoordinator() -> Coordinator { Coordinator(selection: $isPreview) }

    func makeNSView(context: Context) -> ModeSegmentedControl {
        let control = ModeSegmentedControl(labels: ["编辑", "预览"], trackingMode: .selectOne,
                                         target: context.coordinator, action: #selector(Coordinator.selectMode(_:)))
        control.controlSize = .large
        control.segmentStyle = .rounded
        control.setAccessibilityLabel("阅读模式")
        return control
    }

    func updateNSView(_ control: ModeSegmentedControl, context: Context) {
        context.coordinator.selection = $isPreview
        control.setModeSelection(isPreview ? 1 : 0,
                                 animated: !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        control.isEnabled = isEnabled
        control.needsDisplay = true
    }

    final class Coordinator: NSObject {
        var selection: Binding<Bool>
        init(selection: Binding<Bool>) { self.selection = selection }
        @objc func selectMode(_ sender: NSSegmentedControl) {
            selection.wrappedValue = sender.selectedSegment == 1
        }
    }
}
