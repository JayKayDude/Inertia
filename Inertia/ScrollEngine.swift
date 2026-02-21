import Foundation
import CoreGraphics
import ApplicationServices
import os.lock

class ScrollEngine: ObservableObject {
    static let shared = ScrollEngine()

    @Published var isRunning = false

    var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var animationTimer: DispatchSourceTimer?

    private var velocity: Double = 0
    private var lastTickTime: CFAbsoluteTime = 0
    private var tickRate: Double = 0
    private var animating = false
    private var subPixelAccumulator: Double = 0
    private var lineSubPixelAccumulator: Double = 0

    private var cachedFriction: Double = 0.96
    private var cachedBaseSpeed: Double = 4.0
    private var cachedCurveExponent: Double = 1.5
    private var cachedSmoothness: Double = 0.6

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
    private static let velocityThreshold: Double = 120.0
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
        stopAnimation()
        isRunning = false
    }

    func processScrollForPreview(deltaY: Double) -> Double {
        return deltaY * config.baseSpeed * ScrollEngine.pixelsPerTick * 0.3
    }

    func handleScrollEvent(_ event: CGEvent) -> CGEvent? {
        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
        if isContinuous == 1 { return event }

        let rawDelta = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)
        if abs(rawDelta) < 0.001 { return event }

        let now = CFAbsoluteTimeGetCurrent()
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

        cachedBaseSpeed = config.baseSpeed
        cachedCurveExponent = config.curveExponent
        cachedSmoothness = config.smoothness

        let md = config.momentumDuration
        let halfLifeSeconds = 0.02 + md * 0.2
        let halfLifeFrames = halfLifeSeconds * 120.0
        cachedFriction = pow(0.5, 1.0 / halfLifeFrames)

        let direction: Double = rawDelta > 0 ? 1.0 : -1.0

        if dt > 0.16 || direction != lastDirection {
            if consecutiveTickCount >= ScrollEngine.swipeMinTicks
                && dt <= ScrollEngine.swipeMaxInterval {
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
        let fast = fastScrollFactor()
        let impulse = direction * speed * ScrollEngine.pixelsPerTick * fast

        let effectiveSmoothness = min(cachedSmoothness, ScrollEngine.referenceSmoothness)
        let compensation = (1.0 - effectiveSmoothness) / (1.0 - ScrollEngine.referenceSmoothness)

        lock.lock()
        if direction > 0 && velocity < 0 { velocity = 0 }
        if direction < 0 && velocity > 0 { velocity = 0 }
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

    private func computeSpeed(tickRate: Double) -> Double {
        let base = cachedBaseSpeed
        let b = 1.1
        let c = cachedCurveExponent
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

    private func postScrollEvent(pixelDelta: Double) {
        let precise = pixelDelta + subPixelAccumulator
        let rounded = precise.rounded()
        if rounded == 0 {
            subPixelAccumulator = precise
            return
        }
        subPixelAccumulator = precise - rounded
        let intPixels = Int64(rounded)

        let linePrecise = (pixelDelta / ScrollEngine.pixelsPerLine) + lineSubPixelAccumulator
        let lineRounded = linePrecise.rounded()
        lineSubPixelAccumulator = linePrecise - lineRounded
        let lineInt = Int64(lineRounded)
        let fixedPt = lineInt * 65536

        guard let event = CGEvent(source: nil) else { return }

        event.setIntegerValueField(CGEventField(rawValue: 55)!, value: 22)
        event.setIntegerValueField(.scrollWheelEventIsContinuous, value: 1)

        event.setIntegerValueField(.scrollWheelEventDeltaAxis1, value: lineInt)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis1, value: intPixels)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis1, value: fixedPt)

        event.setIntegerValueField(.scrollWheelEventDeltaAxis2, value: 0)
        event.setIntegerValueField(.scrollWheelEventPointDeltaAxis2, value: 0)
        event.setIntegerValueField(.scrollWheelEventFixedPtDeltaAxis2, value: 0)

        event.post(tap: .cgSessionEventTap)
    }

    private func startAnimationIfNeeded() {
        lock.lock()
        guard !animating else { lock.unlock(); return }
        animating = true
        subPixelAccumulator = 0
        lineSubPixelAccumulator = 0
        lock.unlock()

        animationTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInteractive))
        timer.schedule(deadline: .now(), repeating: ScrollEngine.frameInterval)
        timer.setEventHandler { [weak self] in
            self?.animationFrame()
        }
        timer.resume()
        animationTimer = timer
    }

    private func stopAnimation() {
        lock.lock()
        animating = false
        velocity = 0
        subPixelAccumulator = 0
        lineSubPixelAccumulator = 0
        consecutiveSwipeCount = 0
        consecutiveTickCount = 0
        lock.unlock()
        animationTimer?.cancel()
        animationTimer = nil
    }

    private func animationFrame() {
        lock.lock()
        velocity *= cachedFriction

        if abs(velocity) < ScrollEngine.velocityThreshold {
            animating = false
            velocity = 0
            subPixelAccumulator = 0
            lineSubPixelAccumulator = 0
            lock.unlock()
            animationTimer?.cancel()
            animationTimer = nil
            return
        }

        let pixelDelta = velocity * ScrollEngine.frameInterval
        lock.unlock()
        postScrollEvent(pixelDelta: pixelDelta)
    }
}

private func scrollCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
    let engine = Unmanaged<ScrollEngine>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        if engine.isRunning, let tap = engine.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    guard type == .scrollWheel else { return Unmanaged.passRetained(event) }

    if let processed = engine.handleScrollEvent(event) {
        return Unmanaged.passRetained(processed)
    }

    return nil
}
