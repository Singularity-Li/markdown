import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    let store: DocumentStore

    var body: some View {
        HSplitView {
            if store.folderRoot != nil && store.showsSidebar {
                SidebarView(store: store)
                    .frame(minWidth: 190, idealWidth: 240, maxWidth: 360)
            }
            DetailView(store: store, toggleSidebar: { store.showsSidebar.toggle() })
                .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.top, 8)
        .background(Color.clear)
        .onDrop(of: [UTType.fileURL], isTargeted: Binding(
            get: { store.isDropTargeted }, set: { store.isDropTargeted = $0 }
        )) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url else { return }
                DispatchQueue.main.async { store.handleOpen(url) }
            }
            return true
        }
        .overlay {
            if store.isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, lineWidth: 3)
                    .allowsHitTesting(false)
            }
        }
        .alert("无法完成操作", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("好") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}
