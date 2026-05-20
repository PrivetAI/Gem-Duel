import SwiftUI

struct BoardView: View {
    @ObservedObject var vm: BattleViewModel
    let boardSize: CGFloat

    @State private var dragStart: (row: Int, col: Int)? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var invalidShake: (row: Int, col: Int)? = nil

    private let n = BoardEngine.size

    var body: some View {
        let cell = boardSize / CGFloat(n)
        let pad: CGFloat = cell * 0.06
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(GQBTheme.bgDeep.opacity(0.7))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(GQBTheme.cardStroke.opacity(0.6), lineWidth: 1.5))

            // Grid of gems anchored to the parent-passed boardSize (avoids Canvas size pitfall).
            ForEach(0..<n, id: \.self) { r in
                ForEach(0..<n, id: \.self) { c in
                    if r < vm.grid.count, c < vm.grid[r].count, let kind = vm.grid[r][c].kind {
                        let isDragging = dragStart?.row == r && dragStart?.col == c
                        GemView(kind: kind,
                                special: vm.grid[r][c].special,
                                selected: isDragging)
                            .frame(width: cell - pad * 2, height: cell - pad * 2)
                            .position(x: cell * (CGFloat(c) + 0.5),
                                      y: cell * (CGFloat(r) + 0.5))
                            .offset(isDragging ? clampedOffset(cell: cell) : .zero)
                            .modifier(ShakeEffect(animatableData: (invalidShake?.row == r && invalidShake?.col == c) ? 1 : 0))
                            .zIndex(isDragging ? 10 : 0)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .frame(width: boardSize, height: boardSize)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    guard vm.phase == .playerTurn || vm.phase == .onboardingHint else { return }
                    if dragStart == nil {
                        let col = Int(value.startLocation.x / cell)
                        let row = Int(value.startLocation.y / cell)
                        if row >= 0, row < n, col >= 0, col < n {
                            dragStart = (row, col)
                        }
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    defer { dragStart = nil; dragOffset = .zero }
                    guard let start = dragStart else { return }
                    guard vm.phase == .playerTurn || vm.phase == .onboardingHint else { return }
                    let dx = value.translation.width
                    let dy = value.translation.height
                    // Determine swipe direction (dominant axis).
                    var target = start
                    if abs(dx) > abs(dy) {
                        target.col += dx > 0 ? 1 : -1
                    } else {
                        target.row += dy > 0 ? 1 : -1
                    }
                    guard target.row >= 0, target.row < n, target.col >= 0, target.col < n else { return }
                    let ok = vm.attemptSwap(from: (start.row, start.col), to: (target.row, target.col))
                    if !ok {
                        // Invalid swap feedback.
                        triggerShake(start)
                    }
                }
        )
    }

    private func clampedOffset(cell: CGFloat) -> CGSize {
        // Limit the visual drag to roughly one cell in the dominant direction.
        let dx = dragOffset.width, dy = dragOffset.height
        if abs(dx) > abs(dy) {
            return CGSize(width: max(-cell, min(cell, dx)), height: 0)
        } else {
            return CGSize(width: 0, height: max(-cell, min(cell, dy)))
        }
    }

    private func triggerShake(_ pos: (row: Int, col: Int)) {
        invalidShake = pos
        withAnimation(.default) { invalidShake = pos }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            invalidShake = nil
        }
    }
}

// Horizontal shake for invalid swaps.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        let amount: CGFloat = 5
        let shakes: CGFloat = 3
        let translation = amount * sin(animatableData * .pi * shakes)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
