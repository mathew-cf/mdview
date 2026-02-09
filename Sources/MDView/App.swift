import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var appState: AppState?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let appState = appState, let url = urls.first else { return }
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        if isDir.boolValue {
            appState.loadDirectory(url)
        } else {
            appState.loadFile(url)
        }
    }
}

@main
struct MDViewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 500, minHeight: 350)
                .onAppear {
                    appDelegate.appState = appState
                    handleCommandLineArgs()
                }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open…") {
                    appState.openFileOrDirectory()
                }
                .keyboardShortcut("o")

                Button("Quick Open") {
                    appState.showQuickOpen()
                }
                .keyboardShortcut("p")
            }
            CommandGroup(after: .toolbar) {
                Button("Reload") {
                    appState.reload()
                }
                .keyboardShortcut("r")
            }
        }
        .defaultSize(width: 820, height: 700)
    }

    private func handleCommandLineArgs() {
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = args[1]
            let url = URL(fileURLWithPath: path)
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) else { return }

            if isDir.boolValue {
                appState.loadDirectory(url)
            } else {
                appState.loadFile(url)
            }
        }
    }
}
