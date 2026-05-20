import SwiftUI

struct ResultOverlay: View {
    @ObservedObject var vm: BattleViewModel
    @ObservedObject var router: AppRouter
    @State private var appear = false

    private var victory: Bool { vm.phase == .victory }

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).edgesIgnoringSafeArea(.all)
            PanelCard {
                VStack(spacing: 16) {
                    Text(victory ? "Victory" : "Defeat")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(victory ? GQBTheme.gold : GQBTheme.danger)

                    if victory {
                        StarRatingView(earned: vm.earnedStars, total: 3, size: 30)
                            .scaleEffect(appear ? 1 : 0.5)

                        VStack(spacing: 10) {
                            rewardRow(label: "Coins earned",
                                      value: "+\(vm.earnedCoins)",
                                      glyph: AnyView(CoinChipGlyph().frame(width: 16, height: 16)))
                            rewardRow(label: "Experience",
                                      value: "+\(vm.earnedXP) XP",
                                      glyph: AnyView(StarShape().fill(GQBTheme.xp).frame(width: 16, height: 16)))
                            if vm.leveledUp > 0 {
                                rewardRow(label: "Level up!",
                                          value: "+\(vm.leveledUp)",
                                          glyph: AnyView(CrownGlyph().fill(GQBTheme.gold).frame(width: 18, height: 16)))
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("Your hero has fallen. Upgrade your gear and try again.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(GQBTheme.textDim)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 10) {
                        Button(victory ? "Continue" : "Back to Map") {
                            router.activeBattle = nil
                        }
                        .buttonStyle(GoldButtonStyle())

                        if !victory {
                            Button("Retry Battle") {
                                let def = vm.battle
                                router.activeBattle = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    router.activeBattle = def
                                }
                            }
                            .buttonStyle(OutlineButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 36)
            .scaleEffect(appear ? 1 : 0.85)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { appear = true }
        }
    }

    private func rewardRow(label: String, value: String, glyph: AnyView) -> some View {
        HStack {
            glyph
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(GQBTheme.textDim)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.text)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(GQBTheme.bgDeep.opacity(0.5)))
    }
}
