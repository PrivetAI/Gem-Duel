import SwiftUI

// Reusable styled background.
struct GQBBackground: View {
    var body: some View {
        LinearGradient(colors: [GQBTheme.bgDeep, GQBTheme.bgMid, GQBTheme.bgDeep],
                       startPoint: .top, endPoint: .bottom)
            .edgesIgnoringSafeArea(.all)
    }
}

// Gold-bordered panel container.
struct PanelCard<Content: View>: View {
    var padding: CGFloat = 14
    let content: Content
    init(padding: CGFloat = 14, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(GQBTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(GQBTheme.cardStroke.opacity(0.7), lineWidth: 1)
            )
    }
}

// Primary gold button.
struct GoldButtonStyle: ButtonStyle {
    var enabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundColor(enabled ? GQBTheme.bgDeep : GQBTheme.textFaint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(enabled
                          ? LinearGradient(colors: [GQBTheme.gold, GQBTheme.goldDim],
                                           startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [GQBTheme.panelHi, GQBTheme.panel],
                                           startPoint: .top, endPoint: .bottom))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(enabled ? 0.25 : 0.05), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(enabled ? 1 : 0.7)
    }
}

// Secondary outlined button.
struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(GQBTheme.gold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(GQBTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(GQBTheme.gold.opacity(0.6), lineWidth: 1.4))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

// Section header with a small gold rule.
struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(GQBTheme.gold).frame(width: 4, height: 18)
            Text(title)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundColor(GQBTheme.text)
            Spacer()
        }
    }
}

// A labeled stat chip with a custom glyph.
struct StatChip<Glyph: View>: View {
    let glyph: Glyph
    let value: String
    var tint: Color = GQBTheme.gold
    init(value: String, tint: Color = GQBTheme.gold, @ViewBuilder glyph: () -> Glyph) {
        self.value = value
        self.tint = tint
        self.glyph = glyph()
    }
    var body: some View {
        HStack(spacing: 5) {
            glyph.frame(width: 16, height: 16)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.text)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Capsule().fill(GQBTheme.panel))
        .overlay(Capsule().stroke(tint.opacity(0.5), lineWidth: 1))
    }
}

// Back bar used inside pushed screens.
struct GQBNavBar: View {
    let title: String
    var trailing: AnyView? = nil
    let onBack: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                ChevronLeftShape()
                    .stroke(GQBTheme.gold, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 18)
                    .padding(10)
                    .background(Circle().fill(GQBTheme.panel))
                    .overlay(Circle().stroke(GQBTheme.cardStroke, lineWidth: 1))
            }
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(GQBTheme.text)
            Spacer()
            if let trailing = trailing { trailing }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

// Coin glyph used widely.
struct CoinChipGlyph: View {
    var body: some View {
        DiscShape().fill(GQBTheme.gold)
            .overlay(DiscShape().stroke(GQBTheme.goldDeep, lineWidth: 1.5).padding(2))
    }
}
