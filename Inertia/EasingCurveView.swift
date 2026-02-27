import SwiftUI

struct EasingCurveView: View {
    let preset: EasingPreset
    let momentumDuration: Double
    var momentumProgress: Double? = nil

    var body: some View {
        Canvas { context, size in
            let friction = computeFriction()
            let points = generateCurve(friction: friction, width: size.width, height: size.height)

            var baseline = Path()
            baseline.move(to: CGPoint(x: 0, y: size.height))
            baseline.addLine(to: CGPoint(x: size.width, y: size.height))
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

    private func computeFriction() -> Double {
        let halfLifeSeconds = 0.02 + momentumDuration * 0.2
        let halfLifeFrames = halfLifeSeconds * 120.0
        return pow(0.5, 1.0 / halfLifeFrames)
    }

    private func generateCurve(friction: Double, width: CGFloat, height: CGFloat) -> [CGPoint] {
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
            }
        }

        return points
    }
}
