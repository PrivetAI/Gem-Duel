import SwiftUI

struct HeroView: View {
    @EnvironmentObject var store: SaveStore

    var body: some View {
        ZStack {
            GQBBackground()
            ScrollView {
                VStack(spacing: 16) {
                    heroHeader
                    statsCard
                    spellsCard
                    equipCard
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }
        }
        .navigationBarHidden(true)
    }

    private var xpProgress: (current: Int, needed: Int, frac: Double) {
        let base = store.xpForLevel(store.save.heroLevel)
        let next = store.xpForLevel(store.save.heroLevel + 1)
        let cur = store.save.heroXP - base
        let need = max(1, next - base)
        return (cur, need, min(1, Double(cur) / Double(need)))
    }

    private var heroHeader: some View {
        PanelCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(GQBTheme.gold.opacity(0.22)).frame(width: 72, height: 72)
                    HeroMarkShape().fill(GQBTheme.gold).frame(width: 46, height: 52)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Gem Champion")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(GQBTheme.text)
                    Text("Level \(store.save.heroLevel)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(GQBTheme.gold)
                    StatBar(value: xpProgress.current, maxValue: xpProgress.needed, color: GQBTheme.xp, height: 10)
                    Text("\(xpProgress.current) / \(xpProgress.needed) XP to next level")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(GQBTheme.textDim)
                }
            }
        }
    }

    private var statsCard: some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Stats")
                statRow("Max Health", "\(store.heroMaxHP)", GQBTheme.hp,
                        AnyView(HeartShape().fill(GQBTheme.hp)))
                statRow("Sword Bonus", "+\(store.heroAttackBonus)", GQBTheme.danger,
                        AnyView(BladeShape().fill(GQBTheme.danger)))
                statRow("Coins", "\(store.save.coins)", GQBTheme.gold,
                        AnyView(CoinChipGlyph()))
                statRow("Total Stars", "\(store.totalStars) / 180", GQBTheme.gold,
                        AnyView(StarShape().fill(GQBTheme.gold)))
            }
        }
    }

    private func statRow(_ label: String, _ value: String, _ tint: Color, _ glyph: AnyView) -> some View {
        HStack(spacing: 10) {
            glyph.frame(width: 18, height: 18)
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(GQBTheme.textDim)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.text)
        }
    }

    private var spellsCard: some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Spells")
                ForEach(SpellKind.allCases, id: \.rawValue) { spell in
                    let unlocked = store.save.heroLevel >= spell.unlockLevel
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(unlocked ? GQBTheme.panelHi : GQBTheme.panel)
                                .frame(width: 38, height: 38)
                            spellGlyph(spell, unlocked ? GQBTheme.gold : GQBTheme.textFaint)
                                .frame(width: 22, height: 22)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spell.name)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(unlocked ? GQBTheme.text : GQBTheme.textFaint)
                            Text(unlocked ? spell.desc : "Unlocks at level \(spell.unlockLevel)")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(GQBTheme.textDim)
                        }
                        Spacer()
                        if unlocked {
                            HStack(spacing: 3) {
                                TeardropShape().fill(GQBTheme.mana).frame(width: 9, height: 12)
                                Text("\(spell.manaCost)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(GQBTheme.mana)
                            }
                        } else {
                            LockShape().fill(GQBTheme.textFaint).frame(width: 16, height: 18)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder private func spellGlyph(_ spell: SpellKind, _ color: Color) -> some View {
        switch spell {
        case .fireball: FireballGlyph().fill(color)
        case .mend: MendGlyph().fill(color)
        case .earthwall: EarthwallGlyph().stroke(color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        case .frost: FrostGlyph().stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }

    private var equipCard: some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: "Equipped Gear")
                equippedRow(.weapon, store.equippedWeapon)
                equippedRow(.armor, store.equippedArmor)
                equippedRow(.charm, store.equippedCharm)
                NavigationLink(destination: InventoryView()) {
                    Text("Manage Inventory")
                }
                .buttonStyle(OutlineButtonStyle())
            }
        }
    }

    private func equippedRow(_ slot: GearSlot, _ item: GearItem) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(GQBTheme.panelHi).frame(width: 38, height: 38)
                gearGlyph(slot).frame(width: 22, height: 22)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(slot.name): \(item.name)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(GQBTheme.text)
                Text(item.bonusSummary)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(GQBTheme.textDim)
            }
            Spacer()
            tierPips(item.tier)
        }
    }

    @ViewBuilder private func gearGlyph(_ slot: GearSlot) -> some View {
        switch slot {
        case .weapon: WeaponGearGlyph().fill(GQBTheme.gold)
        case .armor: ArmorGearGlyph().fill(GQBTheme.shield)
        case .charm: CharmGearGlyph().fill(GQBTheme.mana)
        }
    }
}

func tierPips(_ tier: Int) -> some View {
    HStack(spacing: 3) {
        ForEach(0..<4, id: \.self) { i in
            Circle()
                .fill(i <= tier ? GQBTheme.gold : GQBTheme.goldDeep.opacity(0.4))
                .frame(width: 6, height: 6)
        }
    }
}
