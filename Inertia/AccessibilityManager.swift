import Cocoa
import ApplicationServices

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()

    @Published var isTrusted = false

    private var pollTimer: Timer?

    init() {
        isTrusted = AXIsProcessTrusted()
        NSLog("[Inertia] AccessibilityManager init: isTrusted=%d", isTrusted ? 1 : 0)
    }

    func ensureAccess(onGranted: @escaping () -> Void) {
        isTrusted = AXIsProcessTrusted()
        NSLog("[Inertia] ensureAccess: isTrusted=%d", isTrusted ? 1 : 0)

        if isTrusted {
            onGranted()
            return
        }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        NSLog("[Inertia] Prompted for accessibility permission")

        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let trusted = AXIsProcessTrusted()
            NSLog("[Inertia] Polling accessibility: trusted=%d", trusted ? 1 : 0)
            if trusted {
                DispatchQueue.main.async {
                    self?.isTrusted = true
                    self?.pollTimer?.invalidate()
                    self?.pollTimer = nil
                    NSLog("[Inertia] Accessibility granted, calling onGranted")
                    onGranted()
                }
            }
        }
    }
}

