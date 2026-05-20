import SwiftUI

struct OnboardingView: View {
    let onDone: () -> Void
    @State private var step = 0

    private let steps: [(title: String, body: String)] = [
        ("Swap to Match", "Drag a gem onto an adjacent gem to swap them. A swap only works if it lines up three or more of the same gem."),
        ("Gem Effects", "Each gem casts a different effect when cleared: Swords strike the enemy, Shields raise block, Hearts heal, Mana charges spells, Coins pay the shop, and Stars charge your ultimate."),
        ("The Enemy Turn", "After your full turn — one swap plus every cascade — the enemy strikes back. Watch its intent badge to plan your defense."),
        ("Spells & Ultimate", "Spend Mana on powerful spells, and unleash your ultimate once the Star meter is full to turn the tide of battle.")
    ]

    var body: some View {
        ZStack {
            GQBBackground()
            VStack(spacing: 22) {
                Spacer()
                stepArt
                    .frame(height: 130)
                Text(steps[step].title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(GQBTheme.gold)
                Text(steps[step].body)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(GQBTheme.text)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? GQBTheme.gold : GQBTheme.panelHi)
                            .frame(width: i == step ? 22 : 8, height: 8)
                    }
                }
                Button(step == steps.count - 1 ? "Begin Quest" : "Next") {
                    if step < steps.count - 1 {
                        withAnimation { step += 1 }
                    } else {
                        onDone()
                    }
                }
                .buttonStyle(GoldButtonStyle())
                .padding(.horizontal, 28)
                Button("Skip") { onDone() }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(GQBTheme.textDim)
                Spacer().frame(height: 12)
            }
        }
    }

    @ViewBuilder private var stepArt: some View {
        switch step {
        case 0:
            HStack(spacing: 10) {
                GemView(kind: .sword).frame(width: 54, height: 54)
                ChevronLeftShape()
                    .stroke(GQBTheme.gold, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: 18, height: 22).rotationEffect(.degrees(180))
                GemView(kind: .heart).frame(width: 54, height: 54)
            }
        case 1:
            HStack(spacing: 10) {
                ForEach(GemKind.allCases, id: \.rawValue) { k in
                    GemView(kind: k).frame(width: 40, height: 40)
                }
            }
        case 2:
            HStack(spacing: 24) {
                ZStack {
                    Circle().fill(GQBTheme.gold.opacity(0.25)).frame(width: 80, height: 80)
                    HeroMarkShape().fill(GQBTheme.gold).frame(width: 48, height: 54)
                }
                SwordCrossGlyph().stroke(GQBTheme.danger, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 28, height: 28)
                ZStack {
                    Circle().fill(GQBTheme.hp.opacity(0.25)).frame(width: 80, height: 80)
                    EnemyMarkShape().fill(GQBTheme.hp).frame(width: 50, height: 50)
                }
            }
        default:
            HStack(spacing: 16) {
                FireballGlyph().fill(GQBTheme.danger).frame(width: 44, height: 44)
                MendGlyph().fill(GQBTheme.hp).frame(width: 40, height: 40)
                EarthwallGlyph().stroke(GQBTheme.shield, style: StrokeStyle(lineWidth: 3, lineJoin: .round)).frame(width: 44, height: 44)
                StarShape().fill(GQBTheme.ultimate).frame(width: 48, height: 48)
            }
        }
    }
}
