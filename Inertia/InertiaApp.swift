import SwiftUI

@main
struct InertiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var config = ScrollConfig.shared
    @StateObject private var engine = ScrollEngine.shared
    @StateObject private var updateChecker = UpdateChecker.shared

    var body: some Scene {
        MenuBarExtra("Inertia", image: "MenuBarIcon") {
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

            Button("About Inertia") {
                appDelegate.showAbout()
            }

            if let version = updateChecker.availableVersion {
                Button("Update Available (v\(version))") {
                    NSWorkspace.shared.open(UpdateChecker.releasesPageURL)
                }
            }

            Divider()

            Button("Quit Inertia") {
                engine.stop()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var settingsWindow: NSWindow?
    private var settingsHostingController: NSHostingController<AnyView>?
    private var aboutWindow: NSWindow?
    private var heightObserver: NSObjectProtocol?
    private var closeObserver: NSObjectProtocol?
    private var backingObserver: NSObjectProtocol?
    private var debounceWorkItem: DispatchWorkItem?
    private let tabBarOffset: CGFloat = 28
    private var hasCompletedInitialLayout = false
    private var lastContentHeight: CGFloat = 0
    private var blockBackingResize = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        AccessibilityManager.shared.ensureAccess {
            if ScrollConfig.shared.enabled {
                ScrollEngine.shared.start()
            }
        }
        if ScrollConfig.shared.globalHotkeyEnabled {
            HotkeyManager.shared.register()
        }
        UpdateChecker.shared.startPeriodicChecks()
    }

    func showSettings() {
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = AnyView(SettingsView()
            .environmentObject(ScrollConfig.shared))

        let hostingController = NSHostingController(rootView: settingsView)
        hostingController.sizingOptions = []
        self.settingsHostingController = hostingController
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Inertia Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 520, height: 600))
        window.minSize = NSSize(width: 520, height: 300)
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        let accessoryVC = NSTitlebarAccessoryViewController()
        accessoryVC.layoutAttribute = .trailing
        let button = NSButton(image: NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "Settings Menu")!, target: self, action: #selector(showExportImportMenu(_:)))
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        accessoryVC.view = button
        window.addTitlebarAccessoryViewController(accessoryVC)

        settingsWindow = window
        hasCompletedInitialLayout = false

        heightObserver = NotificationCenter.default.addObserver(
            forName: .settingsContentHeightChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let height = notification.userInfo?["height"] as? CGFloat else { return }
            self?.debounceWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.animateWindowHeight(contentHeight: height)
            }
            self?.debounceWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
        }

        backingObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeBackingPropertiesNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.blockBackingResize = true
        }

        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            if let obs = self?.heightObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.heightObserver = nil
            }
            if let obs = self?.backingObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.backingObserver = nil
            }
            self?.debounceWorkItem?.cancel()
            self?.settingsHostingController = nil
            self?.settingsWindow = nil
        }
    }

    private func animateWindowHeight(contentHeight: CGFloat) {
        guard let window = settingsWindow else { return }

        if abs(contentHeight - lastContentHeight) < 5 && hasCompletedInitialLayout { return }
        lastContentHeight = contentHeight

        let targetContentHeight = contentHeight + tabBarOffset + 8
        let titleBarHeight = window.frame.height - (window.contentView?.frame.height ?? window.frame.height)
        let targetWindowHeight = targetContentHeight + titleBarHeight

        let screen = window.screen ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let clampedHeight = min(targetWindowHeight, visibleFrame.height)

        let currentTop = window.frame.origin.y + window.frame.height
        var newOriginY = currentTop - clampedHeight
        if newOriginY < visibleFrame.origin.y {
            newOriginY = visibleFrame.origin.y
        }

        let newFrame = NSRect(
            x: window.frame.origin.x,
            y: newOriginY,
            width: window.frame.width,
            height: clampedHeight
        )

        if abs(newFrame.height - window.frame.height) < 1 {
            hasCompletedInitialLayout = true
            return
        }

        if !hasCompletedInitialLayout {
            hasCompletedInitialLayout = true
            window.setFrame(newFrame, display: true)
            return
        }

        if abs(newFrame.height - window.frame.height) < 1 {
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = false
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if sender == settingsWindow {
            defer { blockBackingResize = false }
            if blockBackingResize {
                return sender.frame.size
            }
            return NSSize(width: 520, height: frameSize.height)
        }
        return frameSize
    }

    @objc func showExportImportMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Export Settings...", action: #selector(exportSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Import Settings...", action: #selector(importSettings), keyEquivalent: ""))
        let point = NSPoint(x: 0, y: sender.bounds.height + 4)
        menu.popUp(positioning: nil, at: point, in: sender)
    }

    @objc func exportSettings() {
        ScrollConfig.shared.exportSettings()
    }

    @objc func importSettings() {
        ScrollConfig.shared.importSettings()
    }

    func showAbout() {
        if let window = aboutWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: AboutView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About Inertia"
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        aboutWindow = window
    }
}
