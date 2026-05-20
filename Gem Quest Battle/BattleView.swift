import SwiftUI

struct BattleView: View {
    let battle: BattleDef
    @ObservedObject var router: AppRouter
    @EnvironmentObject var store: SaveStore
    @StateObject private var vm: BattleViewModel
    @State private var paused = false
    @State private var showHint = false

    init(battle: BattleDef, router: AppRouter) {
        self.battle = battle
        self.router = router
        // vm created with a temporary store; replaced in onAppear via environment is not possible for StateObject,
        // so we build it with a shared SaveStore captured from the environment using a holder.
        _vm = StateObject(wrappedValue: BattleViewModel(battle: battle, store: BattleView.storeHolder ?? SaveStore()))
    }

    // Bridge to pass the environment store into StateObject init.
    static var storeHolder: SaveStore?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                GQBBackground()
                content(geo: geo)

                if vm.phase == .onboardingHint || showHint {
                    onboardingOverlay
                }
                if vm.phase == .victory || vm.phase == .defeat {
                    ResultOverlay(vm: vm, router: router)
                }
                if paused {
                    pauseOverlay
                }
            }
        }
        .onAppear {
            if !store.save.onboardingDone {
                showHint = false
            }
        }
    }

    private func content(geo: GeometryProxy) -> some View {
        let screenW = geo.size.width
        let boardSide = min(screenW - 24, geo.size.height * 0.46)
        return VStack(spacing: 8) {
            topBar
            EnemyPanel(vm: vm, region: battle.regionIndex)
            HeroPanel(vm: vm)
            BoardView(vm: vm, boardSize: boardSide)
                .frame(width: boardSide, height: boardSide)
                .frame(maxWidth: .infinity)
            SpellBar(vm: vm)
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var topBar: some View {
        HStack {
            Text(battle.isBoss ? "Boss Battle" : "Battle \(battle.localIndex + 1)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.textDim)
            Text(Region.all[battle.regionIndex].name)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(GQBTheme.textFaint)
            Spacer()
            Button(action: { paused = true }) {
                HStack(spacing: 4) {
                    Rectangle().fill(GQBTheme.gold).frame(width: 4, height: 14)
                    Rectangle().fill(GQBTheme.gold).frame(width: 4, height: 14)
                }
                .padding(8)
                .background(Circle().fill(GQBTheme.panel))
                .overlay(Circle().stroke(GQBTheme.cardStroke, lineWidth: 1))
            }
        }
    }

    private var onboardingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).edgesIgnoringSafeArea(.all)
            PanelCard {
                VStack(spacing: 14) {
                    Text("Your Turn")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(GQBTheme.gold)
                    Text("Drag a gem onto an adjacent one to swap. A swap only works if it forms a line of 3 or more matching gems.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(GQBTheme.text)
                        .multilineTextAlignment(.center)
                    Button("Got it") {
                        vm.dismissOnboardingHint()
                        showHint = false
                    }
                    .buttonStyle(GoldButtonStyle())
                }
            }
            .padding(.horizontal, 36)
        }
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).edgesIgnoringSafeArea(.all)
            PanelCard {
                VStack(spacing: 14) {
                    Text("Paused")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(GQBTheme.text)
                    Button("Resume") { paused = false }
                        .buttonStyle(GoldButtonStyle())
                    Button("Show How to Play") { paused = false; showHint = true }
                        .buttonStyle(OutlineButtonStyle())
                    Button("Retreat to Map") { router.activeBattle = nil }
                        .buttonStyle(OutlineButtonStyle())
                }
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Enemy / Hero panels

struct EnemyPanel: View {
    @ObservedObject var vm: BattleViewModel
    let region: Int

    var body: some View {
        PanelCard(padding: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(Region.all[region].tint.opacity(0.28)).frame(width: 56, height: 56)
                    EnemyMarkShape().fill(Region.all[region].tint).frame(width: 40, height: 40)
                }
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(vm.battle.enemyName)
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(GQBTheme.text)
                            .lineLimit(1)
                        Spacer()
                        intentBadge
                    }
                    StatBar(value: vm.enemyHP, maxValue: vm.enemyMaxHP, color: GQBTheme.hp, height: 12)
                    HStack(spacing: 8) {
                        Text("\(vm.enemyHP) / \(vm.enemyMaxHP)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(GQBTheme.textDim)
                        if vm.enemyShield > 0 {
                            HStack(spacing: 3) {
                                ShieldShape().fill(GQBTheme.shield).frame(width: 11, height: 12)
                                Text("\(vm.enemyShield)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(GQBTheme.shield)
                            }
                        }
                        if vm.enemyFrozen {
                            Text("Frozen")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(GQBTheme.mana)
                        }
                    }
                }
            }
        }
    }

    private var intentBadge: some View {
        HStack(spacing: 4) {
            SwordCrossGlyph().stroke(GQBTheme.danger, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 12, height: 12)
            Text(vm.enemyIntent.label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(GQBTheme.textDim)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(GQBTheme.bgDeep.opacity(0.6)))
    }
}

struct HeroPanel: View {
    @ObservedObject var vm: BattleViewModel

    var body: some View {
        PanelCard(padding: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(GQBTheme.gold.opacity(0.25)).frame(width: 50, height: 50)
                    HeroMarkShape().fill(GQBTheme.gold).frame(width: 34, height: 38)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Hero")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(GQBTheme.text)
                        if vm.heroShield > 0 {
                            HStack(spacing: 3) {
                                ShieldShape().fill(GQBTheme.shield).frame(width: 11, height: 12)
                                Text("\(vm.heroShield)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(GQBTheme.shield)
                            }
                        }
                        if vm.heroPoisonStacks > 0 {
                            Text("Venom \(vm.heroPoisonStacks)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(GQBTheme.poison)
                        }
                        Spacer()
                        Text("\(vm.heroHP) / \(vm.heroMaxHP)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(GQBTheme.textDim)
                    }
                    StatBar(value: vm.heroHP, maxValue: vm.heroMaxHP, color: GQBTheme.hp, height: 11)
                    HStack(spacing: 8) {
                        miniBar(label: "MP", value: vm.mana, max: vm.manaMax, color: GQBTheme.mana)
                        miniBar(label: "ULT", value: vm.ultimate, max: vm.ultimateMax, color: GQBTheme.ultimate)
                    }
                }
            }
        }
    }

    private func miniBar(label: String, value: Int, max: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(color)
            StatBar(value: value, maxValue: max, color: color, height: 8)
        }
    }
}

// MARK: - Spell bar + ultimate

struct SpellBar: View {
    @ObservedObject var vm: BattleViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SpellKind.allCases, id: \.rawValue) { spell in
                spellButton(spell)
            }
            ultButton
        }
    }

    private func spellButton(_ spell: SpellKind) -> some View {
        let unlocked = vm.unlockedSpells.contains(spell)
        let usable = vm.canCast(spell) && unlocked
        return Button(action: { if usable { vm.cast(spell) } }) {
            VStack(spacing: 3) {
                glyph(for: spell, color: usable ? GQBTheme.gold : GQBTheme.textFaint)
                    .frame(width: 24, height: 24)
                if unlocked {
                    HStack(spacing: 2) {
                        TeardropShape().fill(GQBTheme.mana).frame(width: 7, height: 9)
                        Text("\(spell.manaCost)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(usable ? GQBTheme.text : GQBTheme.textFaint)
                    }
                } else {
                    LockShape().fill(GQBTheme.textFaint).frame(width: 12, height: 13)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12).fill(GQBTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(usable ? GQBTheme.gold.opacity(0.7) : GQBTheme.cardStroke.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .opacity(unlocked ? 1 : 0.6)
    }

    private var ultButton: some View {
        let usable = vm.canUltimate
        return Button(action: { if usable { vm.useUltimate() } }) {
            VStack(spacing: 3) {
                StarShape().fill(usable ? GQBTheme.ultimate : GQBTheme.textFaint)
                    .frame(width: 24, height: 24)
                Text(usable ? "READY" : "\(vm.ultimate)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(usable ? GQBTheme.bgDeep : GQBTheme.textFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(usable ? GQBTheme.ultimate.opacity(0.85) : GQBTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(GQBTheme.ultimate.opacity(usable ? 1 : 0.4), lineWidth: 1.4))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func glyph(for spell: SpellKind, color: Color) -> some View {
        switch spell {
        case .fireball: FireballGlyph().fill(color)
        case .mend: MendGlyph().fill(color)
        case .earthwall: EarthwallGlyph().stroke(color, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        case .frost: FrostGlyph().stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}
