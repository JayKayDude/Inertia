import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

class ScrollEngine: ObservableObject {
    static let shared = ScrollEngine()

    @Published var isRunning = false

    var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var animationTimer: DispatchSourceTimer?

    private var velocity: Double = 0
    private var scrollAxisIsHorizontal = false
    private var lastTickTime: CFAbsoluteTime = 0
    private var tickRate: Double = 0
    private var animating = false
    private var subPixelAccumulator: Double = 0
    private var lineSubPixelAccumulator: Double = 0
    private var subPixelAccumulatorX: Double = 0
    private var lineSubPixelAccumulatorX: Double = 0
    private var scrollOriginWindow: Int = 0
    private var momentumFrameCount: Int = 0

    private var cachedFriction: Double = 0.96
    private var cachedBaseSpeed: Double = 4.0
    private var cachedSmoothness: Double = 0.6

    private var cachedScrollAccelerationEnabled: Bool = true
    private var cachedReverseVertical: Bool = false
    private var cachedReverseHorizontal: Bool = false
    private var cachedScrollDistanceMultiplier: Double = 1.0

    private var cachedModifierHotkeysEnabled: Bool = true
    private var cachedFastModifierFlags: CGEventFlags = .maskControl
    private var cachedSlowModifierFlags: CGEventFlags = .maskAlternate
    private var cachedFastMultiplier: Double = 2.0
    private var cachedSlowMultiplier: Double = 0.5

    private var cachedFrontmostBundleID: String?
    private var workspaceObserver: NSObjectProtocol?

    private let config = ScrollConfig.shared
    private let lock = NSLock()

    private var tickRateHistory: [Double] = []
    private static let tickRateHistorySize = 3

    private var consecutiveTickCount: Int = 0
    private var consecutiveSwipeCount: Int = 0
    private var swipeSequenceStartTime: CFAbsoluteTime = 0
    private var swipeSequenceTickCount: Int = 0
    private var lastDirection: Double = 0

    private static let swipeMinTicks: Int = 2
    private static let swipeMaxInterval: Double = 0.4
    private static let swipeMinTickSpeed: Double = 5.0

    private static let frameInterval: Double = 1.0 / 120.0
    private static let pixelsPerTick: Double = 45.0
    private static let velocityThreshold: Double = 30.0
    private static let pixelsPerLine: Double = 10.0
    private static let referenceSmoothness: Double = 0.9

    func start() {
        guard !isRunning else { return }

        NSLog("[Inertia] Starting scroll engine...")

        let mask: CGEventMask = 1 << CGEventType.scrollWheel.rawValue

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: scrollCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("[Inertia] FAILED to create event tap!")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        cachedFrontmostBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self.lock.lock()
            self.cachedFrontmostBundleID = app?.bundleIdentifier
            self.lock.unlock()
            if ScrollConfig.shared.isAppBlacklisted(app?.bundleIdentifier) {
                self.stopAnimation()
            }
        }

        isRunning = true
        NSLog("[Inertia] Scroll engine running")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
        if let obs = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            workspaceObserver = nil
        }
        stopAnimation()
        isRunning = false
    }

    func processScrollForPreview(deltaY: Double) -> Double {
        return deltaY * config.baseSpeed * ScrollEngine.pixelsPerTick * 0.3
    }

    func handleScrollEvent(_ event: CGEvent) -> CGEvent? {
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
        if isContinuous == 1 { return event }

        let scrollTargetBundleID = bundleIDUnderCursor()

        if config.isAppBlacklisted(scrollTargetBundleID) { return event }

        let resolved = config.resolvedSettings(for: scrollTargetBundleID)

        let rawDeltaY = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        let rawDeltaX = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        let flags = CGEventSource.flagsState(.combinedSessionState)
        let shiftHeld = flags.contains(.maskShift)

        let nativeHorizontal = abs(rawDeltaX) > 0.001 && abs(rawDeltaY) < 0.001
        let isHorizontal = shiftHeld || nativeHorizontal

        let rawDelta: Double
        if isHorizontal {
            if !resolved.horizontalScrollEnabled { return event }
            rawDelta = nativeHorizontal ? rawDeltaX : rawDeltaY
        } else {
            rawDelta = rawDeltaY
        }

        if abs(rawDelta) < 0.001 { return event }

        let now = CFAbsoluteTimeGetCurrent()

        lock.lock()

        scrollOriginWindow = windowUnderCursor()

        let dt = now - lastTickTime

        if dt > 0 && dt < 0.16 {
            let instantRate = 1.0 / dt
            tickRateHistory.append(instantRate)
            if tickRateHistory.count > ScrollEngine.tickRateHistorySize {
                tickRateHistory.removeFirst()
            }
            tickRate = tickRateHistory.reduce(0, +) / Double(tickRateHistory.count)
        } else {
            tickRateHistory.removeAll()
            tickRate = 5.0
        }
        lastTickTime = now

        cachedBaseSpeed = resolved.baseSpeed
        cachedSmoothness = resolved.smoothness
        cachedScrollAccelerationEnabled = resolved.scrollAccelerationEnabled
        cachedReverseVertical = resolved.reverseVertical
        cachedReverseHorizontal = resolved.reverseHorizontal
        cachedScrollDistanceMultiplier = resolved.scrollDistanceMultiplier
        cachedModifierHotkeysEnabled = resolved.modifierHotkeysEnabled
        cachedFastModifierFlags = (ModifierKey(rawValue: resolved.fastModifier) ?? .control).flags
        cachedSlowModifierFlags = (ModifierKey(rawValue: resolved.slowModifier) ?? .option).flags
        cachedFastMultiplier = resolved.fastMultiplier
        cachedSlowMultiplier = resolved.slowMultiplier

        let md = resolved.momentumDuration
        let halfLifeSeconds = 0.02 + md * 0.2
        let halfLifeFrames = halfLifeSeconds * 120.0
        cachedFriction = pow(0.5, 1.0 / halfLifeFrames)

        let direction: Double = rawDelta > 0 ? 1.0 : -1.0
        let effectiveDirection = (isHorizontal ? cachedReverseHorizontal : cachedReverseVertical) ? -direction : direction

        if dt > 0.16 || direction != lastDirection {
            if direction != lastDirection || dt > ScrollEngine.swipeMaxInterval {
                consecutiveSwipeCount = 0
            } else if consecutiveTickCount >= ScrollEngine.swipeMinTicks {
                let elapsed = now - swipeSequenceStartTime
                let avgTickSpeed = elapsed > 0 ? Double(swipeSequenceTickCount) / elapsed : 0
                if avgTickSpeed >= ScrollEngine.swipeMinTickSpeed {
                    consecutiveSwipeCount += 1
                } else {
                    consecutiveSwipeCount = 0
                }
            } else {
                consecutiveSwipeCount = 0
            }
            consecutiveTickCount = 0
            swipeSequenceStartTime = now
            swipeSequenceTickCount = 0
        }
        consecutiveTickCount += 1
        swipeSequenceTickCount += 1
        lastDirection = direction

        let speed = computeSpeed(tickRate: tickRate)
        let fast = cachedScrollAccelerationEnabled ? fastScrollFactor() : 1.0
        var impulse = effectiveDirection * speed * ScrollEngine.pixelsPerTick * fast
        impulse *= cachedScrollDistanceMultiplier

        if cachedModifierHotkeysEnabled {
            if flags.contains(cachedFastModifierFlags) {
                impulse *= cachedFastMultiplier
            } else if flags.contains(cachedSlowModifierFlags) {
                impulse *= cachedSlowMultiplier
                let minImpulse = effectiveDirection * ScrollEngine.pixelsPerLine * 0.25
                if abs(impulse) < abs(minImpulse) { impulse = minImpulse }
            }
        }

        let effectiveSmoothness = min(cachedSmoothness, ScrollEngine.referenceSmoothness)
        let ratio = (1.0 - effectiveSmoothness) / (1.0 - ScrollEngine.referenceSmoothness)
        let compensation = pow(ratio, 0.15)

        if isHorizontal != scrollAxisIsHorizontal {
            velocity = 0
            subPixelAccumulator = 0
            lineSubPixelAccumulator = 0
            subPixelAccumulatorX = 0
            lineSubPixelAccumulatorX = 0
            scrollAxisIsHorizontal = isHorizontal
            consecutiveSwipeCount = 0
        }

        if effectiveDirection > 0 && velocity < 0 { velocity = 0 }
        if effectiveDirection < 0 && velocity > 0 { velocity = 0 }
        velocity = velocity * effectiveSmoothness + impulse * compensation
        let maxVelocity = cachedBaseSpeed * 3.0 * ScrollEngine.pixelsPerTick * 4.0 * fast
        velocity = min(max(velocity, -maxVelocity), maxVelocity)

        lock.unlock()

        startAnimationIfNeeded()

        return nil
    }

    private func fastScrollFactor() -> Double {
        let threshold = 2
        let initial = 1.33
        let exponential = 7.5
        if consecutiveSwipeCount < threshold { return 1.0 }
        let n = Double(consecutiveSwipeCount - threshold)
        let factor = initial * pow(exponential, n / exponential)
        return min(factor, 50.0)
    }

    private func bundleIDUnderCursor() -> String? {
        let windowNum = windowUnderCursor()
        guard windowNum != 0 else { return cachedFrontmostBundleID }
        guard let windowInfoList = CGWindowListCopyWindowInfo([.optionIncludingWindow], CGWindowID(windowNum)) as? [[String: Any]],
              let info = windowInfoList.first,
              let pid = info[kCGWindowOwnerPID as String] as? pid_t else {
            return cachedFrontmostBundleID
        }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier ?? cachedFrontmostBundleID
    }

    private func windowUnderCursor() -> Int {
        guard let event = CGEvent(source: nil) else { return 0 }
        let cgPoint = event.location
        let screenHeight = NSScreen.screens.first?.frame.height ?? 0
        let cocoaPoint = NSPoint(x: cgPoint.x, y: screenHeight - cgPoint.y)
        return NSWindow.windowNumber(at: cocoaPoint, belowWindowWithWindowNumber: 0)
    }

    private func computeSpeed(tickRate: Double) -> Double {
        let base = cachedBaseSpeed
        if !cachedScrollAccelerationEnabled { return base * 2.0 }
        let b = 1.1
        let c = 1.5
        let t = 8.0
        let p = 1.33
        let denominator = pow(b, c) - 1.0
        if abs(denominator) < 0.001 { return base }
        let a = (p - 1.0) / denominator

        let x = min(tickRate, 100.0)
        if x < t { return base }

        let multiplier = a * pow(b, (x - t) * c) + 1.0 - a
        let clamped = min(max(multiplier, 1.0), 3.0)
        return base * clamped
    }

    private func startAnimationIfNeeded() {
        lock.lock()
        guard !animating else {
            lock.unlock()
            return
        }
        animating = true
        subPixelAccumulator = 0
        lineSubPixelAccumulator = 0
        subPixelAccumulatorX = 0
        lineSubPixelAccumulatorX = 0

        animationTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: ScrollEngine.frameInterval)
        timer.setEventHandler { [weak self] in
            self?.animationFrame()
        }
        timer.resume()
        animationTimer = timer
        lock.unlock()
    }

    private func stopAnimation() {
        lock.lock()
        animating = false
        velocity = 0
        subPixelAccumulator = 0
        lineSubPixelAccumulator = 0
        subPixelAccumulatorX = 0
        lineSubPixelAccumulatorX = 0
        consecutiveSwipeCount = 0
        consecutiveTickCount = 0
        animationTimer?.cancel()
        animationTimer = nil
        lock.unlock()
    }

    private func animationFrame() {
        lock.lock()
        velocity *= cachedFriction

        if abs(velocity) < ScrollEngine.velocityThreshold {
            animating = false
            velocity = 0
            subPixelAccumulator = 0
            lineSubPixelAccumulator = 0
            subPixelAccumulatorX = 0
            lineSubPixelAccumulatorX = 0
            animationTimer?.cancel()
            animationTimer = nil
            lock.unlock()
            return
        }

        let inMomentum = CFAbsoluteTimeGetCurrent() - lastTickTime > 0.15
        let originWindow = scrollOriginWindow
        let isH = scrollAxisIsHorizontal
        let delta = velocity * ScrollEngine.frameInterval

        let pixelDelta = delta
        let accum = isH ? subPixelAccumulatorX : subPixelAccumulator
        let precise = pixelDelta + accum
        let rounded = precise.rounded()
        var intPixels: Int64 = 0
        if rounded == 0 {
            if isH { subPixelAccumulatorX = precise } else { subPixelAccumulator = precise }
        } else {
            if isH { subPixelAccumulatorX = precise - rounded } else { subPixelAccumulator = precise - rounded }
            intPixels = Int64(rounded)
        }

        var lineInt: Int64 = 0
        if intPixels != 0 {
            let lineAcc = isH ? lineSubPixelAccumulatorX : lineSubPixelAccumulator
            let linePrecise = (pixelDelta / ScrollEngine.pixelsPerLine) + lineAcc
            let lineRounded = linePrecise.rounded()
            if isH { lineSubPixelAccumulatorX = linePrecise - lineRounded } else { lineSubPixelAccumulator = linePrecise - lineRounded }
            lineInt = Int64(lineRounded)
        }

        lock.unlock()

        if inMomentum {
            momentumFrameCount += 1
            if momentumFrameCount % 12 == 0 {
                var currentWindow = 0
                DispatchQueue.main.sync { currentWindow = self.windowUnderCursor() }
                if currentWindow != originWindow && currentWindow != 0 {
                    lock.lock()
                    animating = false
                    velocity = 0
                    subPixelAccumulator = 0
                    lineSubPixelAccumulator = 0
                    subPixelAccumulatorX = 0
                    lineSubPixelAccumulatorX = 0
                    animationTimer?.cancel()
                    animationTimer = nil
                    lock.unlock()
                    return
                }
            }
        } else {
            momentumFrameCount = 0
        }

        if intPixels == 0 { return }

        guard let event = CGEvent(source: nil) else { return }
        event.setIntegerValueField(CGEventField(rawValue: 55)!, value: 22)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)

        if isH {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: 0)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: 0)
            event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: 0)
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: lineInt)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: intPixels)
            event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2, value: lineInt * 65536)
        } else {
            event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: lineInt)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: intPixels)
            event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: lineInt * 65536)
            event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: 0)
            event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: 0)
            event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2, value: 0)
        }

        event.post(tap: .cgSessionEventTap)
    }
}

private func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passUnretained(event) }
    let engine = Unmanaged<ScrollEngine>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        NSLog("[Inertia] *** TAP DISABLED *** type=%d — re-enabling", type.rawValue)
        if engine.isRunning, let tap = engine.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passUnretained(event)
    }

    guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }

    if let processed = engine.handleScrollEvent(event) {
        return Unmanaged.passUnretained(processed)
    }

    return nil
}
