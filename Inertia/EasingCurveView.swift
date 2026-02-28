import SwiftUI

struct EasingCurveView: View {
    let preset: EasingPreset
    let momentumDuration: Double
    var momentumProgress: Double? = nil
    var customFriction: Double = 0.96
    var customShape: Double = 0.0
    var customMode: String = "sliders"
    var customPoints: [CurvePoint] = []
    var isEditing: Bool = false
    var onPointsChanged: (([CurvePoint]) -> Void)? = nil
    var onEditingStarted: (() -> Void)? = nil
    var selectedPointIndex: Int? = nil
    var onSelectionChanged: ((Int?) -> Void)? = nil

    @State private var draggingIndex: Int? = nil
    @State private var dragDidMove = false

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let friction = computeFriction()
            let points = generateCurve(friction: friction, width: size.width, height: size.height)

            ZStack {
                Canvas { context, canvasSize in
                    var baseline = Path()
                    baseline.move(to: CGPoint(x: 0, y: canvasSize.height))
                    baseline.addLine(to: CGPoint(x: canvasSize.width, y: canvasSize.height))
                    context.stroke(baseline, with: .color(.gray.opacity(0.3)), lineWidth: 0.5)

                    guard points.count >= 2 else { return }
                    var curve = Path()
                    curve.move(to: points[0])
                    for i in 1..<points.count {
                        curve.addLine(to: points[i])
                    }
                    context.stroke(curve, with: .color(Color.accentColor), lineWidth: 2)

                    if let progress = momentumProgress {
                        let index = min(Int(progress * Double(points.count - 1)), points.count - 1)
                        let dot = points[index]
                        let radius: CGFloat = 6
                        let circle = Path(ellipseIn: CGRect(x: dot.x - radius, y: dot.y - radius, width: radius * 2, height: radius * 2))
                        context.fill(circle, with: .color(Color.accentColor))
                    }

                    if isEditing && preset == .custom && customMode == "points" {
                        let endRadius: CGFloat = 4
                        let startPt = CGPoint(x: 0, y: 0)
                        let endPt = CGPoint(x: canvasSize.width, y: canvasSize.height)
                        context.fill(Path(ellipseIn: CGRect(x: startPt.x - endRadius, y: startPt.y - endRadius, width: endRadius * 2, height: endRadius * 2)), with: .color(.gray))
                        context.fill(Path(ellipseIn: CGRect(x: endPt.x - endRadius, y: endPt.y - endRadius, width: endRadius * 2, height: endRadius * 2)), with: .color(.gray))

                        let ptRadius: CGFloat = 6
                        for (i, pt) in customPoints.enumerated() {
                            let px = pt.x * canvasSize.width
                            let py = (1.0 - pt.y) * canvasSize.height
                            let isSelected = selectedPointIndex == i
                            let r = isSelected ? ptRadius + 2 : ptRadius
                            let rect = CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)
                            context.fill(Path(ellipseIn: rect), with: .color(isSelected ? .orange : Color.accentColor))
                            context.stroke(Path(ellipseIn: rect), with: .color(.white), lineWidth: isSelected ? 2.5 : 1.5)
                        }
                    }
                }

                if isEditing && preset == .custom && customMode == "points" {
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let w = size.width
                                    let h = size.height
                                    let translation = hypot(value.translation.width, value.translation.height)

                                    if draggingIndex == nil && !dragDidMove {
                                        if translation > 4 {
                                            let loc = value.startLocation
                                            if let idx = closestPointIndex(to: loc, in: size) {
                                                onEditingStarted?()
                                                draggingIndex = idx
                                                dragDidMove = true
                                            } else {
                                                let nx = min(max(loc.x / w, 0.01), 0.99)
                                                let ny = min(max(1.0 - loc.y / h, 0.0), 1.0)
                                                onEditingStarted?()
                                                var pts = customPoints
                                                pts.append(CurvePoint(x: nx, y: ny))
                                                pts.sort { $0.x < $1.x }
                                                onPointsChanged?(pts)
                                                let addedIdx = pts.firstIndex(where: { abs($0.x - nx) < 0.001 && abs($0.y - ny) < 0.001 })
                                                draggingIndex = addedIdx
                                                onSelectionChanged?(addedIdx)
                                                dragDidMove = true
                                            }
                                        }
                                        return
                                    }

                                    if let idx = draggingIndex, idx < customPoints.count {
                                        let cx = min(max(value.location.x / w, 0.01), 0.99)
                                        let cy = min(max(1.0 - value.location.y / h, 0.0), 1.0)
                                        var pts = customPoints
                                        pts[idx] = CurvePoint(x: cx, y: cy)
                                        pts.sort { $0.x < $1.x }
                                        onPointsChanged?(pts)
                                        let newIdx = pts.firstIndex(where: { abs($0.x - cx) < 0.001 && abs($0.y - cy) < 0.001 })
                                        draggingIndex = newIdx
                                        onSelectionChanged?(newIdx)
                                    }
                                }
                                .onEnded { value in
                                    let translation = hypot(value.translation.width, value.translation.height)
                                    if !dragDidMove || translation <= 4 {
                                        let loc = value.startLocation
                                        if let idx = closestPointIndex(to: loc, in: size) {
                                            onSelectionChanged?(selectedPointIndex == idx ? nil : idx)
                                        } else {
                                            let nx = min(max(loc.x / size.width, 0.01), 0.99)
                                            let ny = min(max(1.0 - loc.y / size.height, 0.0), 1.0)
                                            onEditingStarted?()
                                            var pts = customPoints
                                            pts.append(CurvePoint(x: nx, y: ny))
                                            pts.sort { $0.x < $1.x }
                                            onPointsChanged?(pts)
                                            let addedIdx = pts.firstIndex(where: { abs($0.x - nx) < 0.001 && abs($0.y - ny) < 0.001 })
                                            onSelectionChanged?(addedIdx)
                                        }
                                    }
                                    draggingIndex = nil
                                    dragDidMove = false
                                }
                        )
                }
            }
            .overlay(alignment: .topLeading) {
                Text("Fast")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                    .padding(.top, 2)
            }
            .overlay(alignment: .bottomLeading) {
                Text("Slow")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 2)
                    .padding(.bottom, 2)
            }
            .overlay(alignment: .bottomTrailing) {
                Text("Time →")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 2)
                    .padding(.bottom, 2)
            }
        }
    }

    private func closestPointIndex(to location: CGPoint, in size: CGSize) -> Int? {
        let threshold: CGFloat = 14
        var bestIdx: Int? = nil
        var bestDist: CGFloat = .greatestFiniteMagnitude
        for (i, pt) in customPoints.enumerated() {
            let px = pt.x * size.width
            let py = (1.0 - pt.y) * size.height
            let dist = hypot(location.x - px, location.y - py)
            if dist < threshold && dist < bestDist {
                bestDist = dist
                bestIdx = i
            }
        }
        return bestIdx
    }

    private func computeFriction() -> Double {
        let halfLifeSeconds = 0.02 + momentumDuration * 0.2
        let halfLifeFrames = halfLifeSeconds * 120.0
        return pow(0.5, 1.0 / halfLifeFrames)
    }

    private func generateCurve(friction: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
        if preset == .custom {
            return generateCustomCurve(friction: friction, width: width, height: height)
        }

        let threshold = 0.01
        let totalFrames: Double
        switch preset {
        case .linear:
            totalFrames = 200
        default:
            totalFrames = max(log(threshold) / log(friction), 1)
        }

        let steps = 200
        var points: [CGPoint] = []
        var v = 1.0

        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let x = t * Double(width)
            let y = (1.0 - v) * Double(height)
            points.append(CGPoint(x: x, y: y))

            switch preset {
            case .smooth:
                v *= friction
            case .snappy:
                let progress = Double(i) / totalFrames
                v *= friction * (1.0 - 0.08 * (1.0 - progress))
            case .linear:
                v = max(v - (1.0 / Double(steps)), 0)
            case .gradual:
                let progress = Double(i) / totalFrames
                v *= friction + (1.0 - friction) * 0.5 * (1.0 - progress)
            case .custom:
                break
            }
        }

        return points
    }

    private func generateCustomCurve(friction: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
        let steps = 200
        var points: [CGPoint] = []

        if customMode == "points" {
            let allPts = [CurvePoint(x: 0, y: 1)] + customPoints.sorted(by: { $0.x < $1.x }) + [CurvePoint(x: 1, y: 0)]
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let v = interpolateMonotoneCubic(allPts, at: t)
                let x = t * Double(width)
                let y = (1.0 - v) * Double(height)
                points.append(CGPoint(x: x, y: y))
            }
        } else {
            let totalFrames = max(log(0.01) / log(customFriction), 1)
            var v = 1.0
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                let x = t * Double(width)
                let y = (1.0 - v) * Double(height)
                points.append(CGPoint(x: x, y: y))

                let progress = Double(i) / totalFrames
                let shapeFactor = customShape * (1.0 - progress)
                let f = min(customFriction * (1.0 - shapeFactor), 1.0)
                v *= f
            }
        }

        return points
    }

    private func interpolateMonotoneCubic(_ pts: [CurvePoint], at t: Double) -> Double {
        let n = pts.count
        if n == 2 { return 1.0 - t }
        let clamped = min(max(t, 0), 1)

        var k = 0
        for i in 0..<(n - 1) {
            if clamped >= pts[i].x && clamped <= pts[i + 1].x { k = i; break }
            if i == n - 2 { k = i }
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

        let h = dx[k]
        guard h > 0 else { return pts[k].y }
        let tt = (clamped - pts[k].x) / h
        let h00 = (1 + 2 * tt) * (1 - tt) * (1 - tt)
        let h10 = tt * (1 - tt) * (1 - tt)
        let h01 = tt * tt * (3 - 2 * tt)
        let h11 = tt * tt * (tt - 1)
        let result = h00 * pts[k].y + h10 * h * tangents[k] + h01 * pts[k + 1].y + h11 * h * tangents[k + 1]
        return min(max(result, 0), 1)
    }
}
