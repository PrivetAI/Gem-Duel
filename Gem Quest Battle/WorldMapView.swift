import SwiftUI

struct WorldMapView: View {
    @EnvironmentObject var store: SaveStore
    @ObservedObject var router: AppRouter

    var body: some View {
        ZStack {
            GQBBackground()
            ScrollView {
                VStack(spacing: 20) {
                    header
                    ForEach(Region.all) { region in
                        RegionSection(region: region, router: router)
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Gem Quest Battle")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(GQBTheme.text)
                Text("\(store.totalStars) / 180 stars")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(GQBTheme.textDim)
            }
            Spacer()
            StatChip(value: "\(store.save.coins)") { CoinChipGlyph() }
            StatChip(value: "Lv \(store.save.heroLevel)", tint: GQBTheme.xp) {
                CrownGlyph().fill(GQBTheme.gold)
            }
        }
    }
}

private struct RegionSection: View {
    @EnvironmentObject var store: SaveStore
    let region: Region
    @ObservedObject var router: AppRouter

    var body: some View {
        let unlocked = store.isRegionUnlocked(region.id)
        PanelCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(region.tint)
                        .frame(width: 14, height: 28)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Region \(region.id + 1)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(GQBTheme.textFaint)
                        Text(region.name)
                            .font(.system(size: 19, weight: .heavy, design: .rounded))
                            .foregroundColor(GQBTheme.text)
                    }
                    Spacer()
                    if !unlocked {
                        LockShape().fill(GQBTheme.textFaint)
                            .frame(width: 20, height: 22)
                    } else {
                        Text("\(regionStars()) / 36")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(GQBTheme.gold)
                    }
                }

                if unlocked {
                    nodeGrid
                } else {
                    Text("Defeat \(region.id > 0 ? Region.all[region.id - 1].bossName : "") to unlock this region.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(GQBTheme.textDim)
                        .padding(.vertical, 6)
                }
            }
        }
    }

    private func regionStars() -> Int {
        var total = 0
        for l in 0..<12 { total += store.stars(for: region.id * 12 + l) }
        return total
    }

    private var nodeGrid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(0..<12, id: \.self) { local in
                let global = region.id * 12 + local
                NodeButton(global: global, region: region, router: router)
            }
        }
    }
}

private struct NodeButton: View {
    @EnvironmentObject var store: SaveStore
    let global: Int
    let region: Region
    @ObservedObject var router: AppRouter

    var body: some View {
        let def = BattleDef.make(global: global)
        let unlocked = store.isBattleUnlocked(global)
        let stars = store.stars(for: global)
        Button(action: {
            if unlocked {
                BattleView.storeHolder = store
                router.activeBattle = def
            }
        }) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(unlocked ? (def.isBoss ? region.tint : GQBTheme.panelHi) : GQBTheme.panel)
                        .frame(width: 48, height: 48)
                        .overlay(Circle().stroke(def.isBoss ? GQBTheme.gold : GQBTheme.cardStroke,
                                                 lineWidth: def.isBoss ? 2 : 1))
                    if !unlocked {
                        LockShape().fill(GQBTheme.textFaint).frame(width: 18, height: 20)
                    } else if def.isBoss {
                        CrownGlyph().fill(GQBTheme.gold).frame(width: 26, height: 22)
                    } else {
                        Text("\(def.localIndex + 1)")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(GQBTheme.text)
                    }
                }
                if unlocked {
                    StarRatingView(earned: stars, total: 3, size: 8)
                } else {
                    StarRatingView(earned: 0, total: 3, size: 8).opacity(0.3)
                }
            }
        }
        .buttonStyle(.plain)
        .opacity(unlocked ? 1 : 0.6)
    }
}
