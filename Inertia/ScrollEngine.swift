import Foundation
import CoreGraphics
import ApplicationServices
import AppKit

class ScrollEngine: ObservableObject {
    static let shared = ScrollEngine()

    @Published var isRunning = false
    @Published var momentumProgress: Double? = nil
    @Published var activeScrollBundleID: String? = nil

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

    private var cachedFriction: Double = 0.96
    private var cachedBaseSpeed: Double = 4.0
    private var cachedSmoothness: Double = 0.6
    private var cachedEasingPreset: EasingPreset = .smooth
    private var cachedCustomFriction: Double = 0.96
    private var cachedCustomShape: Double = 0.0
    private var cachedCustomMode: String = "sliders"
    private var cachedCustomPoints: [CurvePoint] = []
    private var cachedCurvePts: [CurvePoint] = []
    private var cachedCurveDx: [Double] = []
    private var cachedCurveTangents: [Double] = []
    private var momentumPhaseStarted: Bool = false
    private var momentumFrameCount: Int = 0
    private var momentumInitialVelocity: Double = 0
    private var cachedTotalFrames: Double = 120

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
    private var cachedScrollTargetBundleID: String?
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

    private func estimatedTotalFrames(friction: Double, initialV: Double) -> Double {
        guard friction > 0 && friction < 1 && abs(initialV) > Self.velocityThreshold else { return 120 }
        return log(Self.velocityThreshold / abs(initialV)) / log(friction)
    }

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

    func reEnableEventTapIfNeeded() {
        lock.lock()
        let tap = isRunning ? eventTap : nil
        lock.unlock()
        if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
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

        cachedScrollTargetBundleID = scrollTargetBundleID

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
            if !resolved.verticalScrollEnabled { return event }
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
        cachedEasingPreset = EasingPreset(rawValue: resolved.easingPreset) ?? .smooth
        if cachedEasingPreset == .custom {
            cachedCustomFriction = resolved.customEasingFriction
            cachedCustomShape = resolved.customEasingShape
            cachedCustomMode = resolved.customEasingMode
            if let data = resolved.customEasingPoints.data(using: .utf8),
               let pts = try? JSONDecoder().decode([CurvePoint].self, from: data) {
                cachedCustomPoints = pts
            } else {
                cachedCustomPoints = []
            }
            if cachedCustomMode == "points" {
                precomputeCurveTangents()
            }
        }

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
        let holdingFast = cachedModifierHotkeysEnabled && flags.contains(cachedFastModifierFlags)
        let fast = cachedScrollAccelerationEnabled ? fastScrollFactor(holdingFastModifier: holdingFast) : 1.0
        var impulse = effectiveDirection * speed * ScrollEngine.pixelsPerTick * fast
        impulse *= cachedScrollDistanceMultiplier

        if cachedModifierHotkeysEnabled {
            if holdingFast {
                impulse *= cachedFastMultiplier
            } else if flags.contains(cachedSlowModifierFlags) {
                impulse *= cachedSlowMultiplier
                let minImpulse = effectiveDirection * Self.velocityThreshold * 1.1
                if abs(impulse) < abs(minImpulse) { impulse = minImpulse }
                let maxSlowImpulse = cachedBaseSpeed * Self.pixelsPerTick * cachedSlowMultiplier
                if abs(impulse) > maxSlowImpulse { impulse = effectiveDirection * maxSlowImpulse }
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
            momentumPhaseStarted = false
        }

        if effectiveDirection > 0 && velocity < 0 { velocity = 0; momentumPhaseStarted = false }
        if effectiveDirection < 0 && velocity > 0 { velocity = 0; momentumPhaseStarted = false }
        if momentumPhaseStarted {
            momentumPhaseStarted = false
            momentumFrameCount = 0
            DispatchQueue.main.async { [weak self] in
                self?.momentumProgress = nil
            }
        }
        velocity = velocity * effectiveSmoothness + impulse * compensation
        let maxVelocity = cachedBaseSpeed * 3.0 * ScrollEngine.pixelsPerTick * 4.0 * fast
        velocity = min(max(velocity, -maxVelocity), maxVelocity)

        lock.unlock()

        startAnimationIfNeeded()

        return nil
    }

    private func fastScrollFactor(holdingFastModifier: Bool) -> Double {
        let threshold = holdingFastModifier ? 4 : 3
        let exponential = holdingFastModifier ? 1.5 : 7.5
        let initial = holdingFastModifier ? 1.1 : 1.33
        if consecutiveSwipeCount < threshold { return 1.0 }
        let n = Double(consecutiveSwipeCount - threshold)
        let factor = initial * pow(exponential, n / exponential)
        return min(factor, 50.0)
    }

    private func bundleIDUnderCursor() -> String? {
        let windowNum = windowUnderCursor()
        lock.lock()
        let fallback = cachedFrontmostBundleID
        lock.unlock()
        guard windowNum != 0 else { return fallback }
        guard let windowInfoList = CGWindowListCopyWindowInfo([.optionIncludingWindow], CGWindowID(windowNum)) as? [[String: Any]],
              let info = windowInfoList.first,
              let pid = info[kCGWindowOwnerPID as String] as? pid_t else {
            return fallback
        }
        return NSRunningApplication(processIdentifier: pid)?.bundleIdentifier ?? fallback
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
        momentumPhaseStarted = false
        momentumFrameCount = 0
        animationTimer?.cancel()
        animationTimer = nil
        lock.unlock()
        DispatchQueue.main.async { [weak self] in
            self?.momentumProgress = nil
            self?.activeScrollBundleID = nil
        }
    }

    private func animationFrame() {
        lock.lock()

        let inMomentum = CFAbsoluteTimeGetCurrent() - lastTickTime > 0.15

        if inMomentum && !momentumPhaseStarted {
            momentumPhaseStarted = true
            momentumFrameCount = 0
            momentumInitialVelocity = velocity
            let frictionForEstimate = cachedEasingPreset == .custom ? cachedCustomFriction : cachedFriction
            cachedTotalFrames = max(estimatedTotalFrames(friction: frictionForEstimate, initialV: velocity), 10)
            let bundleID = cachedScrollTargetBundleID
            DispatchQueue.main.async { [weak self] in
                self?.activeScrollBundleID = bundleID
            }
        }

        if inMomentum && momentumPhaseStarted {
            momentumFrameCount += 1
            let t = min(Double(momentumFrameCount) / cachedTotalFrames, 1.0)

            switch cachedEasingPreset {
            case .smooth:
                velocity *= cachedFriction
            case .snappy:
                let f = cachedFriction * (1.0 - 0.08 * (1.0 - t))
                velocity *= f
            case .linear:
                let decrement = abs(momentumInitialVelocity) / cachedTotalFrames
                let sign: Double = velocity > 0 ? 1.0 : -1.0
                velocity = sign * max(abs(velocity) - decrement, 0)
            case .gradual:
                let f = cachedFriction + (1.0 - cachedFriction) * 0.5 * (1.0 - t)
                velocity *= f
            case .custom:
                if cachedCustomMode == "points" && !cachedCustomPoints.isEmpty {
                    let targetV = interpolateCurve(at: t) * abs(momentumInitialVelocity)
                    let sign: Double = momentumInitialVelocity > 0 ? 1.0 : -1.0
                    velocity = sign * targetV
                } else {
                    let shapeFactor = cachedCustomShape * (1.0 - t)
                    let f = min(cachedCustomFriction * (1.0 - shapeFactor), 1.0)
                    velocity *= f
                }
            }

            if momentumFrameCount % 2 == 0 || momentumFrameCount == 1 {
                let progress = t
                DispatchQueue.main.async { [weak self] in
                    self?.momentumProgress = progress
                }
            }
        } else {
            velocity *= cachedFriction
        }

        if abs(velocity) < ScrollEngine.velocityThreshold {
            animating = false
            velocity = 0
            subPixelAccumulator = 0
            lineSubPixelAccumulator = 0
            subPixelAccumulatorX = 0
            lineSubPixelAccumulatorX = 0
            momentumPhaseStarted = false
            momentumFrameCount = 0
            animationTimer?.cancel()
            animationTimer = nil
            lock.unlock()
            DispatchQueue.main.async { [weak self] in
                self?.momentumProgress = nil
                self?.activeScrollBundleID = nil
            }
            return
        }
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

        let shouldCheckWindow = inMomentum

        lock.unlock()

        if shouldCheckWindow {
            let currentWindow = windowUnderCursor()
            if currentWindow != originWindow && currentWindow != 0 {
                stopAnimation()
                return
            }
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

    private func precomputeCurveTangents() {
        let pts = [CurvePoint(x: 0, y: 1)] + cachedCustomPoints.sorted(by: { $0.x < $1.x }) + [CurvePoint(x: 1, y: 0)]
        let n = pts.count
        if n == 2 {
            cachedCurvePts = pts
            cachedCurveDx = [1.0]
            cachedCurveTangents = [-1.0, -1.0]
            return
        }

        let dx = (0..<(n - 1)).map { pts[$0 + 1].x - pts[$0].x }
        let dy = (0..<(n - 1)).map { pts[$0 + 1].y - pts[$0].y }
        var m = (0..<(n - 1)).map { dx[$0] > 0 ? dy[$0] / dx[$0] : 0.0 }

        var tangents = Array(repeating: 0.0, count: n)
        tangents[0] = m[0]
        tangents[n - 1] = m[n - 2]
        for i in 1..<(n - 1) {
            if m[i - 1] * m[i] <= 0 {
                tangents[i] = 0
            } else {
                tangents[i] = (m[i - 1] + m[i]) / 2.0
            }
        }

        for i in 0..<(n - 1) {
            guard dx[i] > 0, m[i] != 0 else { continue }
            let alpha = tangents[i] / m[i]
            let beta = tangents[i + 1] / m[i]
            if alpha < 0 { tangents[i] = 0 }
            if beta < 0 { tangents[i + 1] = 0 }
            let mag = alpha * alpha + beta * beta
            if mag > 9 {
                let tau = 3.0 / sqrt(mag)
                tangents[i] = tau * alpha * m[i]
                tangents[i + 1] = tau * beta * m[i]
            }
        }

        cachedCurvePts = pts
        cachedCurveDx = dx
        cachedCurveTangents = tangents
    }

    private func interpolateCurve(at t: Double) -> Double {
        let pts = cachedCurvePts
        let n = pts.count
        if n < 2 { return 1.0 - t }
        if n == 2 { return 1.0 - t }
        let clamped = min(max(t, 0), 1)

        var k = 0
        for i in 0..<(n - 1) {
            if clamped >= pts[i].x && clamped <= pts[i + 1].x { k = i; break }
            if i == n - 2 { k = i }
        }

        let h = cachedCurveDx[k]
        guard h > 0 else { return pts[k].y }
        let tangents = cachedCurveTangents
        let tt = (clamped - pts[k].x) / h
        let h00 = (1 + 2 * tt) * (1 - tt) * (1 - tt)
        let h10 = tt * (1 - tt) * (1 - tt)
        let h01 = tt * tt * (3 - 2 * tt)
        let h11 = tt * tt * (tt - 1)
        let result = h00 * pts[k].y + h10 * h * tangents[k] + h01 * pts[k + 1].y + h11 * h * tangents[k + 1]
        return min(max(result, 0), 1)
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
        engine.reEnableEventTapIfNeeded()
        return Unmanaged.passUnretained(event)
    }

    guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }

    if let processed = engine.handleScrollEvent(event) {
        return Unmanaged.passUnretained(processed)
    }

    return nil
}
