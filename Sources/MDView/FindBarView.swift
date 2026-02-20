import SwiftUI
import WebKit

struct FindBarView: View {
    @Binding var isPresented: Bool
    weak var webView: WKWebView?

    @State private var query = ""
    @State private var matchCount = 0
    @State private var currentIndex = -1
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 12))

            TextField("Find…", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($isFieldFocused)
                .onSubmit { next() }

            if matchCount > 0 {
                Text("\(currentIndex + 1) of \(matchCount)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            } else if !query.isEmpty {
                Text("No matches")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Button(action: prev) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderless)
            .disabled(matchCount == 0)

            Button(action: next) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.borderless)
            .disabled(matchCount == 0)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 340)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .background(
            KeyEventMonitor { keyCode in
                if keyCode == 53 {
                    dismiss()
                    return true
                }
                return false
            }
        )
        .onAppear {
            query = ""
            matchCount = 0
            currentIndex = -1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
        .onChange(of: query) { _ in
            search()
        }
    }

    private func search() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            evalJS("clearFind()")
            return
        }
        let escaped = trimmed
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
        evalJS("findInPage('\(escaped)')")
    }

    private func next() {
        evalJS("findNext()")
    }

    private func prev() {
        evalJS("findPrev()")
    }

    private func dismiss() {
        evalJS("clearFind()")
        withAnimation(.easeOut(duration: 0.12)) {
            isPresented = false
        }
    }

    private func evalJS(_ js: String) {
        webView?.evaluateJavaScript(js) { result, _ in
            guard let json = result as? String,
                  let data = json.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else { return }
            matchCount = dict["total"] as? Int ?? 0
            currentIndex = dict["current"] as? Int ?? -1
        }
    }
}
