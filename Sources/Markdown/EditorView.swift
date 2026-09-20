import SwiftUI

struct EditorView: View {
    let store: DocumentStore

    var body: some View {
        TextEditor(text: Binding(
            get: { store.markdownText },
            set: { store.updateText($0) }
        ))
        .font(.system(.body, design: .monospaced))
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .padding(12)
    }
}