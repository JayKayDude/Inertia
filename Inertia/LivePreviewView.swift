import SwiftUI
import AppKit

struct LivePreviewView: View {
    @EnvironmentObject var config: ScrollConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewArea(label: "Vertical") {
                ScrollablePreview()
                    .environmentObject(config)
            }

            previewArea(label: "Horizontal") {
                HorizontalPreview()
                    .environmentObject(config)
            }

            previewArea(label: "Both") {
                CombinedPreview()
                    .environmentObject(config)
            }
        }
    }

    private func previewArea<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
                .frame(maxHeight: .infinity)
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
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {}

    private func generatePreviewContent() -> String {
        var lines: [String] = []
        lines.append("Scroll here to test vertical scrolling")
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
}

struct HorizontalPreview: NSViewRepresentable {
    @EnvironmentObject var config: ScrollConfig

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor

        let textView = PreviewTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .labelColor
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)

        textView.string = generateHorizontalContent()

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.height]
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {}

    private func generateHorizontalContent() -> String {
        var lines: [String] = []
        lines.append("Scroll horizontally (Shift+wheel or native) ──▶  " + String(repeating: "═══ ", count: 60))
        for i in 1...5 {
            let content = (1...40).map { "[\(i).\($0)]" }.joined(separator: " ── ")
            lines.append(content)
        }
        lines.append(String(repeating: "═══ ", count: 60) + " ◀── End")
        return lines.joined(separator: "\n")
    }
}

struct CombinedPreview: NSViewRepresentable {
    @EnvironmentObject var config: ScrollConfig

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor

        let textView = PreviewTextView()
        textView.isEditable = false
        textView.isSelectable = false
        textView.backgroundColor = .textBackgroundColor
        textView.textColor = .labelColor
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)

        textView.string = generateCombinedContent()

        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = []
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = false

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {}

    private func generateCombinedContent() -> String {
        var lines: [String] = []
        lines.append("Scroll both directions ──▶")
        lines.append(String(repeating: "═", count: 200))
        for row in 1...60 {
            let cells = (1...30).map { String(format: "[%02d,%02d]", row, $0) }.joined(separator: " ")
            lines.append(String(format: "%3d │ %@", row, cells))
        }
        lines.append(String(repeating: "═", count: 200))
        lines.append("End")
        return lines.joined(separator: "\n")
    }
}

class PreviewTextView: NSTextView {
    private var engine: ScrollEngine { ScrollEngine.shared }

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

        guard let scrollView = enclosingScrollView,
              let clipView = scrollView.contentView as? NSClipView else { return }

        let rawDeltaY = Double(event.scrollingDeltaY)
        let rawDeltaX = Double(event.scrollingDeltaX)

        var origin = clipView.bounds.origin
        let docFrame = scrollView.documentView?.frame ?? .zero

        if abs(rawDeltaY) > 0.001 {
            let processed = engine.processScrollForPreview(deltaY: rawDeltaY)
            origin.y -= CGFloat(processed)
            let maxY = max(0, docFrame.height - clipView.bounds.height)
            origin.y = min(max(origin.y, 0), maxY)
        }

        if abs(rawDeltaX) > 0.001 {
            let processed = engine.processScrollForPreview(deltaY: rawDeltaX)
            origin.x -= CGFloat(processed)
            let maxX = max(0, docFrame.width - clipView.bounds.width)
            origin.x = min(max(origin.x, 0), maxX)
        }

        clipView.scroll(to: origin)
        scrollView.reflectScrolledClipView(clipView)
    }
}
