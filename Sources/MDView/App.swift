import SwiftUI
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pendingOpenURL: URL?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        handleOpenURL(url)
    }

    func application(_ application: NSApplication, openFile filename: String) -> Bool {
        handleOpenURL(URL(fileURLWithPath: filename))
        return true
    }

    func application(_ application: NSApplication, openFiles filenames: [String]) {
        guard let filename = filenames.first else { return }
        handleOpenURL(URL(fileURLWithPath: filename))
    }

    private func handleOpenURL(_ url: URL) {
        if let appState = activeAppState() {
            _ = appState.openURL(url)
            return
        }
        pendingOpenURL = url
    }

    func consumePendingOpenURL(for appState: AppState) {
        guard let url = pendingOpenURL else { return }
        pendingOpenURL = nil
        _ = appState.openURL(url)
    }
}

@main
struct MDViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            AppWindowView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    Task { @MainActor in
                        activeAppState()?.openFileOrDirectory()
                    }
                }
                .keyboardShortcut("o")

                Button("Quick Open") {
                    Task { @MainActor in
                        activeAppState()?.showQuickOpen()
                    }
                }
                .keyboardShortcut("p")
            }
            CommandGroup(after: .textEditing) {
                Button("Find…") {
                    Task { @MainActor in
                        activeAppState()?.showFind()
                    }
                }
                .keyboardShortcut("f")
            }
            CommandGroup(after: .toolbar) {
                Button("Reload") {
                    Task { @MainActor in
                        activeAppState()?.reload()
                    }
                }
                .keyboardShortcut("r")

                Divider()

                Button("Zoom In") {
                    Task { @MainActor in
                        activeAppState()?.zoomIn()
                    }
                }
                .keyboardShortcut("+")

                Button("Zoom Out") {
                    Task { @MainActor in
                        activeAppState()?.zoomOut()
                    }
                }
                .keyboardShortcut("-")

                Button("Actual Size") {
                    Task { @MainActor in
                        activeAppState()?.resetZoom()
                    }
                }
                .keyboardShortcut("0")
            }
        }
        .defaultSize(width: 820, height: 700)
    }
}

private struct AppWindowView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        ContentView()
            .environmentObject(appState)
            .frame(minWidth: 500, minHeight: 350)
            .background(
                WindowAccessor { window in
                    WindowRegistry.shared.register(window: window, state: appState)
                    if let appDelegate = NSApp.delegate as? AppDelegate {
                        appDelegate.consumePendingOpenURL(for: appState)
                    }
                }
            )
            .onAppear {
                Task { @MainActor in
                    if !handleCommandLineArgs() {
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.consumePendingOpenURL(for: appState)
                        }
                    }
                }
            }
    }

    @MainActor
    private func handleCommandLineArgs() -> Bool {
        let args = CommandLine.arguments
        guard args.count > 1 else { return false }
        guard !CommandLineState.didHandle else { return false }
        CommandLineState.didHandle = true

        let url = URL(fileURLWithPath: args[1])
        return appState.openURL(url)
    }
}

@MainActor
private enum CommandLineState {
    static var didHandle = false
}

private struct WindowAccessor: NSViewRepresentable {
    let onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = WindowAccessorView()
        view.onResolve = onResolve
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? WindowAccessorView {
            view.onResolve = onResolve
            view.resolveIfPossible()
        }
    }
}

private final class WindowAccessorView: NSView {
    var onResolve: ((NSWindow) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        resolveIfPossible()
    }

    func resolveIfPossible() {
        if let window = window {
            onResolve?(window)
        }
    }
}

@MainActor
private func activeAppState() -> AppState? {
    if let keyWindow = NSApp.keyWindow,
       let appState = WindowRegistry.shared.appState(for: keyWindow) {
        return appState
    }

    return WindowRegistry.shared.anyAppState()
}

@MainActor
private final class WindowRegistry {
    static let shared = WindowRegistry()
    private var states: [ObjectIdentifier: Weak<AppState>] = [:]

    func register(window: NSWindow, state: AppState) {
        states[ObjectIdentifier(window)] = Weak(state)
        cleanup()
    }

    func appState(for window: NSWindow) -> AppState? {
        cleanup()
        return states[ObjectIdentifier(window)]?.value
    }

    func anyAppState() -> AppState? {
        cleanup()
        return states.values.compactMap { $0.value }.first
    }

    private func cleanup() {
        states = states.filter { $0.value.value != nil }
    }
}

private final class Weak<T: AnyObject> {
    weak var value: T?

    init(_ value: T) {
        self.value = value
    }
}
