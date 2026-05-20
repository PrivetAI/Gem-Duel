import SwiftUI

struct ShopView: View {
    @EnvironmentObject var store: SaveStore
    @State private var flashID: Int? = nil

    var body: some View {
        ZStack {
            GQBBackground()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(GearSlot.allCases, id: \.rawValue) { slot in
                            slotSection(slot)
                        }
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
            Text("Gear Shop")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(GQBTheme.text)
            Spacer()
            StatChip(value: "\(store.save.coins)") { CoinChipGlyph() }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    private func slotSection(_ slot: GearSlot) -> some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: slot.name + " Tiers")
                ForEach(GearItem.items(for: slot)) { item in
                    shopRow(item)
                }
            }
        }
    }

    private func shopRow(_ item: GearItem) -> some View {
        let owned = store.owns(item)
        let affordable = store.save.coins >= item.cost
        return HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(GQBTheme.panelHi).frame(width: 40, height: 40)
                gearGlyph(item.slot).frame(width: 22, height: 22)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(GQBTheme.text)
                    tierPips(item.tier)
                }
                Text(item.bonusSummary)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(GQBTheme.textDim)
            }
            Spacer()
            buyControl(item: item, owned: owned, affordable: affordable)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(GQBTheme.gold, lineWidth: flashID == item.id ? 2 : 0)
        )
    }

    @ViewBuilder private func buyControl(item: GearItem, owned: Bool, affordable: Bool) -> some View {
        if owned {
            Text("Owned")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.xp)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(GQBTheme.panel))
        } else {
            Button(action: {
                if store.buy(item) {
                    flashID = item.id
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { flashID = nil }
                }
            }) {
                HStack(spacing: 4) {
                    CoinChipGlyph().frame(width: 13, height: 13)
                    Text("\(item.cost)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(affordable ? GQBTheme.bgDeep : GQBTheme.textFaint)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(affordable ? GQBTheme.gold : GQBTheme.panel))
                .overlay(Capsule().stroke(GQBTheme.gold.opacity(affordable ? 0 : 0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!affordable)
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
