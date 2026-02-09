import SwiftUI
import AppKit

struct QuickOpenView: View {
    @Binding var isPresented: Bool
    let files: [URL]
    let directoryURL: URL?
    let onSelect: (URL) -> Void

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool

    private var results: [SearchResult] {
        let mapped = files.map { url in
            SearchResult(
                url: url,
                relativePath: DirectoryScanner.relativePath(for: url, from: directoryURL)
            )
        }

        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return mapped }

        return mapped.compactMap { result in
            guard let s = FuzzyMatch.score(query: trimmed, target: result.relativePath) else {
                return nil
            }
            return SearchResult(url: result.url, relativePath: result.relativePath, score: s)
        }
        .sorted { $0.score > $1.score }
    }

    private var visibleResults: [SearchResult] {
        Array(results.prefix(20))
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField

            if !files.isEmpty {
                Divider()
                resultsList
            }
        }
        .frame(width: 500)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.25), radius: 20, y: 8)
        .background(
            KeyEventMonitor { keyCode in
                switch keyCode {
                case 126:
                    selectedIndex = max(0, selectedIndex - 1)
                    return true
                case 125:
                    let maxIdx = max(0, visibleResults.count - 1)
                    selectedIndex = min(maxIdx, selectedIndex + 1)
                    return true
                case 36:
                    openSelected()
                    return true
                case 53:
                    dismiss()
                    return true
                default:
                    return false
                }
            }
        )
        .onAppear {
            query = ""
            selectedIndex = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isSearchFocused = true
            }
        }
        .onChange(of: query) { _ in
            selectedIndex = 0
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            TextField("Search files…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isSearchFocused)
        }
        .padding(12)
    }

    private var resultsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if visibleResults.isEmpty {
                        Text("No matching files")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                            .padding(12)
                    } else {
                        ForEach(Array(visibleResults.enumerated()), id: \.offset) { idx, result in
                            resultRow(result, selected: idx == selectedIndex)
                                .id(idx)
                                .onTapGesture {
                                    selectedIndex = idx
                                    openSelected()
                                }
                        }
                    }
                }
            }
            .frame(maxHeight: 320)
            .onChange(of: selectedIndex) { idx in
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo(idx, anchor: .center)
                }
            }
        }
    }

    private func resultRow(_ result: SearchResult, selected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.text")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
            Text(result.relativePath)
                .font(.system(size: 13))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(selected ? Color.accentColor.opacity(0.2) : Color.clear)
                .padding(.horizontal, 4)
        )
        .contentShape(Rectangle())
    }

    private func openSelected() {
        let r = visibleResults
        guard selectedIndex >= 0, selectedIndex < r.count else { return }
        onSelect(r[selectedIndex].url)
        dismiss()
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.12)) {
            isPresented = false
        }
    }
}

struct SearchResult {
    let url: URL
    let relativePath: String
    var score: Int = 0
}

struct KeyEventMonitor: NSViewRepresentable {
    let handler: (UInt16) -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.handler = handler
        context.coordinator.startMonitoring()
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.handler = handler
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopMonitoring()
    }

    class Coordinator {
        var handler: ((UInt16) -> Bool)?
        private var monitor: Any?

        func startMonitoring() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if let handled = self?.handler?(event.keyCode), handled {
                    return nil
                }
                return event
            }
        }

        func stopMonitoring() {
            if let m = monitor { NSEvent.removeMonitor(m) }
            monitor = nil
        }

        deinit { stopMonitoring() }
    }
}
