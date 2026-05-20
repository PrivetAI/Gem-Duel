import SwiftUI

struct BestiaryView: View {
    @EnvironmentObject var store: SaveStore

    var body: some View {
        ZStack {
            GQBBackground()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 14) {
                        archetypeCard
                        bossCard
                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var header: some View {
        HStack {
            Text("Bestiary")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(GQBTheme.text)
            Spacer()
            let total = EnemyBehavior.allCases.count + Region.all.count
            let found = store.save.unlockedEnemies.count + store.save.unlockedBosses.count
            Text("\(found) / \(total)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.gold)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private var archetypeCard: some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Enemy Archetypes")
                ForEach(EnemyBehavior.allCases, id: \.rawValue) { b in
                    let known = store.save.unlockedEnemies.contains(b.rawValue)
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(GQBTheme.panelHi).frame(width: 44, height: 44)
                            EnemyMarkShape().fill(known ? GQBTheme.hp : GQBTheme.textFaint)
                                .frame(width: 30, height: 30)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(known ? b.displayName : "??? Unknown")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(known ? GQBTheme.text : GQBTheme.textFaint)
                            Text(known ? b.lore : "Defeat this foe to reveal its lore.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(GQBTheme.textDim)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }

    private var bossCard: some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Region Bosses")
                ForEach(Region.all) { region in
                    let known = store.save.unlockedBosses.contains(region.id)
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(region.tint.opacity(0.3)).frame(width: 44, height: 44)
                            CrownGlyph().fill(known ? region.tint : GQBTheme.textFaint)
                                .frame(width: 28, height: 24)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(known ? region.bossName : "Sealed Boss")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(known ? GQBTheme.text : GQBTheme.textFaint)
                            Text(known ? "Vanquished — guardian of \(region.name)." :
                                    "Conquer \(region.name) to unseal.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(GQBTheme.textDim)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
}
