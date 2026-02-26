import Cocoa
import ApplicationServices

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()

    @Published var isTrusted = false

    private var pollTimer: Timer?

    init() {
        isTrusted = AXIsProcessTrusted()
    }

    func ensureAccess(onGranted: @escaping () -> Void) {
        isTrusted = AXIsProcessTrusted()

        if isTrusted {
            onGranted()
            return
        }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            let trusted = AXIsProcessTrusted()
            if trusted {
                DispatchQueue.main.async {
                    self?.isTrusted = true
                    self?.pollTimer?.invalidate()
                    self?.pollTimer = nil
                    onGranted()
                }
            }
        }
    }
}
