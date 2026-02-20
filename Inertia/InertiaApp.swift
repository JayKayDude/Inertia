import SwiftUI

@main
struct InertiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var config = ScrollConfig.shared
    @StateObject private var engine = ScrollEngine.shared

    var body: some Scene {
        MenuBarExtra("Inertia", systemImage: "computermouse.fill") {
            Toggle("Enable Inertia", isOn: Binding(
                get: { config.enabled },
                set: { newValue in
                    config.enabled = newValue
                    if newValue {
                        engine.start()
                    } else {
                        engine.stop()
                    }
                }
            ))

            Divider()

            Button("Settings...") {
                appDelegate.showSettings()
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Quit Inertia") {
                engine.stop()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[Inertia] App launched")
        AccessibilityManager.shared.ensureAccess {
            NSLog("[Inertia] Accessibility callback fired, starting engine")
            if ScrollConfig.shared.enabled {
                ScrollEngine.shared.start()
            } else {
                NSLog("[Inertia] Engine not started — enabled is false")
            }
        }
    }

    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environmentObject(ScrollConfig.shared)

        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Inertia Settings"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 420, height: 600))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
    }
}
