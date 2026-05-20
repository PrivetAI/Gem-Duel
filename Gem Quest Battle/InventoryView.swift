import SwiftUI

struct InventoryView: View {
    @EnvironmentObject var store: SaveStore
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            GQBBackground()
            VStack(spacing: 0) {
                GQBNavBar(title: "Inventory") { presentationMode.wrappedValue.dismiss() }
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

    private func slotSection(_ slot: GearSlot) -> some View {
        PanelCard {
            VStack(spacing: 12) {
                SectionHeader(title: slot.name)
                ForEach(GearItem.items(for: slot)) { item in
                    let owned = store.owns(item)
                    let equipped = store.isEquipped(item)
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(owned ? GQBTheme.panelHi : GQBTheme.panel)
                                .frame(width: 38, height: 38)
                            gearGlyph(slot, owned).frame(width: 22, height: 22)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(owned ? GQBTheme.text : GQBTheme.textFaint)
                            Text(item.bonusSummary)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(GQBTheme.textDim)
                        }
                        Spacer()
                        actionView(item: item, owned: owned, equipped: equipped)
                    }
                }
            }
        }
    }

    @ViewBuilder private func actionView(item: GearItem, owned: Bool, equipped: Bool) -> some View {
        if equipped {
            Text("Equipped")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.bgDeep)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(GQBTheme.gold))
        } else if owned {
            Button(action: { store.equip(item) }) {
                Text("Equip")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(GQBTheme.gold)
                    .padding(.horizontal, 12).padding(.vertical, 7)
                    .background(Capsule().stroke(GQBTheme.gold, lineWidth: 1.4))
            }
            .buttonStyle(.plain)
        } else {
            HStack(spacing: 4) {
                LockShape().fill(GQBTheme.textFaint).frame(width: 12, height: 14)
                Text("Buy in Shop")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(GQBTheme.textFaint)
            }
        }
    }

    @ViewBuilder private func gearGlyph(_ slot: GearSlot, _ owned: Bool) -> some View {
        let color = owned ? colorFor(slot) : GQBTheme.textFaint
        switch slot {
        case .weapon: WeaponGearGlyph().fill(color)
        case .armor: ArmorGearGlyph().fill(color)
        case .charm: CharmGearGlyph().fill(color)
        }
    }

    private func colorFor(_ slot: GearSlot) -> Color {
        switch slot {
        case .weapon: return GQBTheme.gold
        case .armor: return GQBTheme.shield
        case .charm: return GQBTheme.mana
        }
    }
}
