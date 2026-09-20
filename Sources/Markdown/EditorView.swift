import SwiftUI

struct EditorView: View {
    let document: OpenDocument

    var body: some View {
        TextEditor(text: Binding(
            get: { document.text },
            set: { document.text = $0 }
        ))
        .font(.system(.body, design: .monospaced))
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .padding(12)
    }
}