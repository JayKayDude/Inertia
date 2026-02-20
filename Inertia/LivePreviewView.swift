import SwiftUI
import AppKit

struct LivePreviewView: View {
    @EnvironmentObject var config: ScrollConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Live Preview")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollablePreview()
                .environmentObject(config)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.separator, lineWidth: 1)
                )
        }
    }
}

struct ScrollablePreview: NSViewRepresentable {
    @EnvironmentObject var config: ScrollConfig

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor

        let textView = PreviewTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .labelColor
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)

        let content = generatePreviewContent()
        textView.string = content

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        context.coordinator.scrollView = scrollView
        context.coordinator.config = config

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.config = config
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func generatePreviewContent() -> String {
        var lines: [String] = []
        lines.append("Scroll here to test your settings")
        lines.append(String(repeating: "─", count: 40))
        lines.append("")

        for i in 1...80 {
            lines.append(String(format: "%3d │ The quick brown fox jumps over the lazy dog", i))
        }

        lines.append("")
        lines.append(String(repeating: "─", count: 40))
        lines.append("End of preview")
        return lines.joined(separator: "\n")
    }

    class Coordinator {
        weak var scrollView: NSScrollView?
        var config: ScrollConfig?
    }
}

class PreviewTextView: NSTextView {
    private var engine: ScrollEngine { ScrollEngine.shared }
    private var config: ScrollConfig { ScrollConfig.shared }

    override func scrollWheel(with event: NSEvent) {
        guard !event.momentumPhase.contains(.changed),
              !event.momentumPhase.contains(.began) else {
            super.scrollWheel(with: event)
            return
        }

        let isContinuous = event.hasPreciseScrollingDeltas
        if isContinuous {
            super.scrollWheel(with: event)
            return
        }

        let rawDelta = Double(event.scrollingDeltaY)
        guard abs(rawDelta) > 0.001 else { return }

        let processed = engine.processScrollForPreview(deltaY: rawDelta)

        guard let scrollView = enclosingScrollView,
              let clipView = scrollView.contentView as? NSClipView else { return }

        var origin = clipView.bounds.origin
        origin.y -= CGFloat(processed)

        let maxY = max(0, (scrollView.documentView?.frame.height ?? 0) - clipView.bounds.height)
        origin.y = min(max(origin.y, 0), maxY)

        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
    }
}
