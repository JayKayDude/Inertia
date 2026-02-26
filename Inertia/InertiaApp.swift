import SwiftUI

@main
struct InertiaApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var config = ScrollConfig.shared
    @StateObject private var engine = ScrollEngine.shared

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

            Button("Credits") {
                appDelegate.showCredits()
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
    private var creditsWindow: NSWindow?
    private var heightObserver: NSObjectProtocol?
    private var closeObserver: NSObjectProtocol?
    private var frameObserver: NSObjectProtocol?
    private var screenObserver: NSObjectProtocol?
    private var backingObserver: NSObjectProtocol?
    private var debounceWorkItem: DispatchWorkItem?
    private let tabBarOffset: CGFloat = 28
    private var hasCompletedInitialLayout = false
    private var lastContentHeight: CGFloat = 0
    private var lastLoggedFrame: NSRect = .zero

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
        if ScrollConfig.shared.globalHotkeyEnabled {
            HotkeyManager.shared.register()
        }
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
        window.setContentSize(NSSize(width: 520, height: 476))
        window.minSize = NSSize(width: 520, height: 300)
        window.delegate = self
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        settingsWindow = window
        hasCompletedInitialLayout = false

        heightObserver = NotificationCenter.default.addObserver(
            forName: .settingsContentHeightChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let height = notification.userInfo?["height"] as? CGFloat else {
                NSLog("[Inertia] heightObserver: no height in userInfo")
                return
            }
            NSLog("[Inertia] heightObserver received height=%.1f", height)
            self?.debounceWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.animateWindowHeight(contentHeight: height)
            }
            self?.debounceWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
        }

        frameObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self, let w = self.settingsWindow else { return }
            let f = w.frame
            if abs(f.height - self.lastLoggedFrame.height) > 0.5 || abs(f.width - self.lastLoggedFrame.width) > 0.5 {
                NSLog("[Inertia] DEBUG didResize: frame=%@ contentView=%@ backingScale=%.1f screen=%@",
                      NSStringFromRect(f),
                      NSStringFromRect(w.contentView?.frame ?? .zero),
                      w.backingScaleFactor,
                      w.screen?.localizedName ?? "nil")
                self.lastLoggedFrame = f
            }
        }

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeScreenNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            guard let self, let w = self.settingsWindow else { return }
            NSLog("[Inertia] DEBUG didChangeScreen: frame=%@ backingScale=%.1f screen=%@",
                  NSStringFromRect(w.frame),
                  w.backingScaleFactor,
                  w.screen?.localizedName ?? "nil")
        }

        backingObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeBackingPropertiesNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            guard let self, let w = self.settingsWindow else { return }
            let oldScale = (notification.userInfo?[NSWindow.oldScaleFactorUserInfoKey] as? CGFloat) ?? 0
            NSLog("[Inertia] DEBUG didChangeBackingProperties: oldScale=%.1f newScale=%.1f frame=%@ contentView=%@",
                  oldScale,
                  w.backingScaleFactor,
                  NSStringFromRect(w.frame),
                  NSStringFromRect(w.contentView?.frame ?? .zero))

            guard self.lastContentHeight > 0 else { return }
            let targetContentHeight = self.lastContentHeight + self.tabBarOffset + 8
            let titleBarHeight = w.frame.height - (w.contentView?.frame.height ?? w.frame.height)
            let targetWindowHeight = targetContentHeight + titleBarHeight
            let screen = w.screen ?? NSScreen.main
            let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
            let clampedHeight = min(targetWindowHeight, visibleFrame.height)
            let currentTop = w.frame.origin.y + w.frame.height
            var newOriginY = currentTop - clampedHeight
            if newOriginY < visibleFrame.origin.y {
                newOriginY = visibleFrame.origin.y
            }
            let newFrame = NSRect(x: w.frame.origin.x, y: newOriginY, width: w.frame.width, height: clampedHeight)
            w.setFrame(newFrame, display: true)
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
            if let obs = self?.frameObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.frameObserver = nil
            }
            if let obs = self?.screenObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.screenObserver = nil
            }
            if let obs = self?.backingObserver {
                NotificationCenter.default.removeObserver(obs)
                self?.backingObserver = nil
            }
            self?.debounceWorkItem?.cancel()
            self?.settingsHostingController = nil
        }
    }

    private func animateWindowHeight(contentHeight: CGFloat) {
        guard let window = settingsWindow else {
            NSLog("[Inertia] animateWindowHeight: no settingsWindow")
            return
        }

        NSLog("[Inertia] animateWindowHeight called, contentHeight=%.1f (last=%.1f)", contentHeight, lastContentHeight)

        if abs(contentHeight - lastContentHeight) < 5 && hasCompletedInitialLayout {
            NSLog("[Inertia] skipping — content height barely changed")
            return
        }
        lastContentHeight = contentHeight

        NSLog("[Inertia] window.frame=%@, contentView.frame=%@",
              NSStringFromRect(window.frame),
              NSStringFromRect(window.contentView?.frame ?? .zero))

        let targetContentHeight = contentHeight + tabBarOffset + 8
        let titleBarHeight = window.frame.height - (window.contentView?.frame.height ?? window.frame.height)
        let targetWindowHeight = targetContentHeight + titleBarHeight

        NSLog("[Inertia] targetContentHeight=%.1f, titleBarHeight=%.1f, targetWindowHeight=%.1f",
              targetContentHeight, titleBarHeight, targetWindowHeight)

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

        NSLog("[Inertia] currentHeight=%.1f, newHeight=%.1f, diff=%.1f",
              window.frame.height, newFrame.height, abs(newFrame.height - window.frame.height))

        if abs(newFrame.height - window.frame.height) < 1 {
            NSLog("[Inertia] skipping — height diff < 1")
            return
        }

        if !hasCompletedInitialLayout {
            hasCompletedInitialLayout = true
            NSLog("[Inertia] initial layout — setting frame without animation")
            window.setFrame(newFrame, display: true)
            return
        }

        NSLog("[Inertia] animating window to new frame: %@", NSStringFromRect(newFrame))
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = false
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(newFrame, display: true)
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if sender == settingsWindow {
            return NSSize(width: 520, height: frameSize.height)
        }
        return frameSize
    }

    func showCredits() {
        if let window = creditsWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: CreditsView())
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Credits"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 350, height: 250))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        creditsWindow = window
    }
}
