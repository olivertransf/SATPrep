//
//  SplitPaneView.swift
//  Studium
//
//  Draggable split pane matching the web's passage / Desmos split handle.
//  Persists the split fraction to UserDefaults (same keys as the web's localStorage).
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SplitPaneView<Left: View, Right: View>: View {
    @Binding var fraction: Double
    let persistKey: String
    let left: Left
    let right: Right

    @GestureState private var dragOffset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isHandleHovered = false

    private let handleWidth: CGFloat = 16
    private let minFraction = 0.22
    private let maxFraction = 0.78

    init(
        fraction: Binding<Double>,
        persistKey: String,
        @ViewBuilder left: () -> Left,
        @ViewBuilder right: () -> Right
    ) {
        self._fraction = fraction
        self.persistKey = persistKey
        self.left = left()
        self.right = right()
    }

    private var effectiveFraction: Double {
        guard containerWidth > 0 else { return fraction }
        let raw = fraction + Double(dragOffset) / Double(containerWidth)
        return max(minFraction, min(maxFraction, raw))
    }

    private var leftWidth: CGFloat {
        guard containerWidth > 0 else { return 280 }
        return max(80, CGFloat(effectiveFraction) * containerWidth - handleWidth / 2)
    }

    var body: some View {
        HStack(spacing: 0) {
            left
                .frame(width: leftWidth)
                .frame(maxHeight: .infinity)
                .clipped()

            dragHandle

            right
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemGroupedBackground)
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: _SplitContainerWidthKey.self, value: geo.size.width)
            }
        )
        .onPreferenceChange(_SplitContainerWidthKey.self) { w in
            if w > 0 { containerWidth = w }
        }
    }

    @ViewBuilder
    private var dragHandle: some View {
        let isDragging = dragOffset != 0
        let drag = DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                let newF = fraction + Double(value.translation.width) / Double(max(1, containerWidth))
                fraction = max(minFraction, min(maxFraction, newF))
                UserDefaults.standard.set(fraction, forKey: persistKey)
            }

        ZStack {
            Rectangle()
                .fill(
                    isDragging
                        ? Color.accentColor.opacity(0.18)
                        : (isHandleHovered ? Color.secondary.opacity(0.14) : Color.secondary.opacity(0.07))
                )

            VStack(spacing: 3) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 9, weight: .bold))
                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .frame(width: 3, height: 3)
                    }
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(isDragging ? Color.accentColor : Color.secondary)
            .opacity(isHandleHovered || isDragging ? 1 : 0.6)
        }
        .frame(width: handleWidth)
        .frame(maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(drag)
        .overlay(Divider().frame(maxWidth: 1).frame(maxHeight: .infinity), alignment: .leading)
        .overlay(Divider().frame(maxWidth: 1).frame(maxHeight: .infinity), alignment: .trailing)
        #if os(macOS)
        .onHover { inside in
            isHandleHovered = inside
            if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
        }
        #endif
    }
}

private struct _SplitContainerWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let n = nextValue()
        if n > 0 { value = n }
    }
}
