import AppKit
import SwiftUI

/// Read-only text that keeps the native text selection and text services menu.
/// The optional click handler lets dictionary rows open while the text remains
/// selectable and keeps the normal NSTextView copy / Look Up behavior intact.
public struct SelectableText: NSViewRepresentable {
    private let text: String
    private let font: NSFont
    private let color: NSColor
    private let onClick: (() -> Void)?

    public init(
        _ text: String,
        font: NSFont = .systemFont(ofSize: 14),
        color: NSColor = .labelColor,
        onClick: (() -> Void)? = nil
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.onClick = onClick
    }

    public func makeNSView(context: Context) -> NSTextView {
        let view = SelectableNativeTextView(frame: .zero)
        view.isEditable = false
        view.isSelectable = true
        view.isRichText = false
        view.importsGraphics = false
        view.drawsBackground = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.isHorizontallyResizable = false
        view.isVerticallyResizable = true
        view.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        view.minSize = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.textContainer?.widthTracksTextView = true
        view.textContainer?.heightTracksTextView = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.onClick = onClick
        applyText(to: view)
        return view
    }

    public func updateNSView(_ nsView: NSTextView, context: Context) {
        if let view = nsView as? SelectableNativeTextView {
            view.onClick = onClick
        }
        applyText(to: nsView)
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextView, context: Context) -> CGSize? {
        let candidateWidth = proposal.width ?? nsView.frame.width
        let width = candidateWidth.isFinite && candidateWidth > 1 ? candidateWidth : 300
        nsView.setFrameSize(NSSize(width: width, height: max(nsView.frame.height, font.pointSize * 1.4)))
        nsView.textContainer?.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)

        guard let container = nsView.textContainer, let layoutManager = nsView.layoutManager else {
            return CGSize(width: width, height: ceil(font.pointSize * 1.4))
        }
        layoutManager.ensureLayout(for: container)
        let usedRect = layoutManager.usedRect(for: container)
        let measuredHeight = usedRect.height + nsView.textContainerInset.height * 2
        let minimumHeight = font.ascender - font.descender + font.leading
        return CGSize(width: width, height: ceil(max(minimumHeight, measuredHeight)))
    }

    private func applyText(to view: NSTextView) {
        let colorIsCurrent = (view.textColor ?? .labelColor).isEqual(color)
        guard view.string != text || view.font != font || !colorIsCurrent else { return }

        let priorSelection = view.selectedRange()
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 2
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        view.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: attributes))
        view.font = font
        view.textColor = color

        let stringLength = (text as NSString).length
        let location = min(priorSelection.location, stringLength)
        let length = min(priorSelection.length, stringLength - location)
        view.setSelectedRange(NSRange(location: location, length: length))
    }
}

private final class SelectableNativeTextView: NSTextView {
    var onClick: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onClick?()
        super.mouseDown(with: event)
    }
}
