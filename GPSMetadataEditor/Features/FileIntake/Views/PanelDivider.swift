import AppKit
import SwiftUI

struct PanelDivider: View {
    @Binding var leftWidth: CGFloat
    let totalWidth: CGFloat
    @State private var isHovered = false
    @State private var dragStartWidth: CGFloat? = nil

    private let hitWidth: CGFloat = 8
    private let minLeft = AppDesign.Layout.leftColumnMinimumWidth
    private let minRight = AppDesign.Layout.rightColumnMinimumWidth

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(isHovered ? Color.accentColor : Color.secondary.opacity(0.5))
                    .frame(width: 3, height: 3)
            }
        }
        .frame(width: hitWidth)
        .contentShape(.rect)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                NSCursor.resizeLeftRight.set()
            } else if dragStartWidth == nil {
                NSCursor.arrow.set()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if dragStartWidth == nil {
                        dragStartWidth = leftWidth
                    }
                    let newWidth = (dragStartWidth ?? leftWidth) + value.translation.width
                    leftWidth = max(minLeft, min(newWidth, totalWidth - minRight - hitWidth))
                }
                .onEnded { _ in
                    dragStartWidth = nil
                    if isHovered {
                        NSCursor.resizeLeftRight.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
        )
        .accessibilityHidden(true)
    }
}
