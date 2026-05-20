import SwiftUI

struct GemQuestBattleLoadingScreen: View {
    @State private var spin = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [GQBTheme.bgDeep, GQBTheme.bgMid],
                           startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 28) {
                ZStack {
                    // Rotating ring of gem shapes.
                    ForEach(0..<6, id: \.self) { i in
                        let kind = GemKind(rawValue: i) ?? .sword
                        GemView(kind: kind)
                            .frame(width: 34, height: 34)
                            .offset(y: -54)
                            .rotationEffect(.degrees(Double(i) / 6.0 * 360.0))
                    }
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    // Center crown
                    CrownGlyph()
                        .fill(GQBTheme.gold)
                        .frame(width: 46, height: 40)
                        .scaleEffect(pulse ? 1.08 : 0.94)
                }
                .frame(width: 150, height: 150)

                Text("Gem Quest Battle")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(GQBTheme.text)
                Text("Preparing the duel...")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(GQBTheme.textDim)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { spin = true }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}
