import SwiftUI
import Combine

// Describes what the enemy intends to do next turn (shown in its panel).
enum EnemyIntent: Equatable {
    case attack(Int)
    case heal
    case shieldUp
    case poison
    case enrage
    case bossPhase

    var label: String {
        switch self {
        case .attack(let v): return "Attack \(v)"
        case .heal: return "Mending"
        case .shieldUp: return "Guarding"
        case .poison: return "Venom"
        case .enrage: return "Enraging"
        case .bossPhase: return "Awakening"
        }
    }
}

enum BattlePhase: Equatable {
    case onboardingHint
    case playerTurn
    case resolving
    case enemyTurn
    case victory
    case defeat
}

// A short floating combat-log message.
struct FloatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let color: Color
    static func == (l: FloatMessage, r: FloatMessage) -> Bool { l.id == r.id }
}

final class BattleViewModel: ObservableObject {
    let battle: BattleDef
    private unowned let store: SaveStore

    @Published var grid: [[Cell]] = []
    @Published var phase: BattlePhase = .playerTurn

    // Hero state
    @Published var heroHP: Int
    @Published var heroMaxHP: Int
    @Published var heroShield: Int = 0
    @Published var mana: Int = 0
    let manaMax = 30
    @Published var ultimate: Int = 0
    let ultimateMax = 100

    // Enemy state
    @Published var enemyHP: Int
    @Published var enemyMaxHP: Int
    @Published var enemyShield: Int
    @Published var enemyIntent: EnemyIntent = .attack(0)
    @Published var enemyPoisonStacks: Int = 0
    @Published var enemyFrozen: Bool = false

    // Combat log
    @Published var messages: [FloatMessage] = []
    @Published var lastSwordHits: Int = 0

    // Rewards (set on victory)
    @Published var earnedStars: Int = 0
    @Published var earnedCoins: Int = 0
    @Published var earnedXP: Int = 0
    @Published var leveledUp: Int = 0

    // Tracking for star rating
    private var turnsTaken = 0
    private var coinsCollected = 0
    private var damageTaken = 0
    private var bossPhase2 = false

    // Enemy behavior runtime
    private var enemyTurnCounter = 0
    private var berserkRamp = 0
    private var stackerBonus = 0

    private var engine: BoardEngine

    init(battle: BattleDef, store: SaveStore) {
        self.battle = battle
        self.store = store
        self.heroMaxHP = store.heroMaxHP
        self.heroHP = store.heroMaxHP
        self.enemyMaxHP = battle.enemyMaxHP
        self.enemyHP = battle.enemyMaxHP
        self.enemyShield = battle.enemyBlock
        let seed = gemQuestMixSeed(battle.globalIndex, 0xBA771E, store.save.heroLevel)
        self.engine = BoardEngine(seed: seed)
        self.grid = engine.grid
        if !store.save.onboardingDone {
            phase = .onboardingHint
        }
        planEnemyIntent()
    }

    // MARK: - Derived

    var equippedWeapon: GearItem { store.equippedWeapon }
    var equippedArmor: GearItem { store.equippedArmor }
    var equippedCharm: GearItem { store.equippedCharm }
    var heroAttackBonus: Int { store.heroAttackBonus }
    var unlockedSpells: [SpellKind] { store.unlockedSpells() }

    func canCast(_ spell: SpellKind) -> Bool {
        phase == .playerTurn && mana >= spell.manaCost
    }

    var canUltimate: Bool { phase == .playerTurn && ultimate >= ultimateMax }

    // MARK: - Messages

    private func pushMessage(_ text: String, _ color: Color) {
        let msg = FloatMessage(text: text, color: color)
        messages.append(msg)
        if messages.count > 5 { messages.removeFirst(messages.count - 5) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            self?.messages.removeAll { $0.id == msg.id }
        }
    }

    // MARK: - Player swap

    func attemptSwap(from: (Int, Int), to: (Int, Int)) -> Bool {
        guard phase == .playerTurn || phase == .onboardingHint else { return false }
        guard engine.areAdjacent(from, to) else { return false }
        guard let tally = engine.performSwap(from, to) else {
            return false  // illegal swap — caller reverts visual
        }
        if phase == .onboardingHint {
            // First successful swap completes the hint; mark onboarding done at battle start only.
        }
        phase = .resolving
        turnsTaken += 1
        applyTally(tally)
        engine.ensurePlayable()
        withAnimation(.easeInOut(duration: 0.18)) {
            grid = engine.grid
        }
        // Check victory before enemy acts.
        if enemyHP <= 0 {
            finishVictory()
            return true
        }
        // Enemy turn after a brief beat.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
            self?.runEnemyTurn()
        }
        return true
    }

    private func applyTally(_ tally: EffectTally) {
        // Sword damage scales with hero attack bonus and cascade depth.
        if tally.swordHits > 0 {
            let cascadeBonus = max(0, tally.cascades - 1)
            let raw = tally.swordHits * (4 + heroAttackBonus) + cascadeBonus * 3
            dealDamageToEnemy(raw)
            lastSwordHits = tally.swordHits
            pushMessage("Strike \(raw)", GQBTheme.danger)
        }
        if tally.shieldGems > 0 {
            let perShield = 3 + equippedArmor.bonusBlockPerShield
            heroShield = min(heroShield + tally.shieldGems * perShield, 999)
            pushMessage("Block +\(tally.shieldGems * perShield)", GQBTheme.shield)
        }
        if tally.heartGems > 0 {
            let heal = tally.heartGems * 5
            heroHP = min(heroHP + heal, heroMaxHP)
            pushMessage("Heal +\(heal)", GQBTheme.hp)
        }
        if tally.manaGems > 0 {
            let per = 2 + equippedCharm.bonusManaPerGem
            mana = min(mana + tally.manaGems * per, manaMax)
        }
        if tally.coinGems > 0 {
            let per = 1 + equippedCharm.bonusCoinPerGem
            let c = tally.coinGems * per
            coinsCollected += c
            pushMessage("Coins +\(c)", GQBTheme.gold)
        }
        if tally.starGems > 0 {
            ultimate = min(ultimate + tally.starGems * 6, ultimateMax)
        }
    }

    private func dealDamageToEnemy(_ amount: Int) {
        var dmg = amount
        if enemyShield > 0 {
            let absorbed = min(enemyShield, dmg)
            enemyShield -= absorbed
            dmg -= absorbed
        }
        enemyHP = max(0, enemyHP - dmg)
        // Boss two-phase: at 50% HP the boss awakens (enrage + heal shield).
        if battle.isBoss && !bossPhase2 && enemyHP <= enemyMaxHP / 2 && enemyHP > 0 {
            bossPhase2 = true
            enemyShield += 12 + battle.regionIndex * 3
            berserkRamp += 4
            pushMessage("\(battle.enemyName) awakens!", GQBTheme.ultimate)
        }
    }

    // MARK: - Spells

    func cast(_ spell: SpellKind) {
        guard canCast(spell) else { return }
        mana -= spell.manaCost
        switch spell {
        case .fireball:
            let dmg = 22 + store.save.heroLevel * 3 + heroAttackBonus * 2
            dealDamageToEnemy(dmg)
            pushMessage("Fireball \(dmg)", GQBTheme.danger)
        case .mend:
            let heal = 30 + store.save.heroLevel * 4
            heroHP = min(heroHP + heal, heroMaxHP)
            pushMessage("Mend +\(heal)", GQBTheme.hp)
        case .earthwall:
            let block = 26 + store.save.heroLevel * 3
            heroShield = min(heroShield + block, 999)
            pushMessage("Earthwall +\(block)", GQBTheme.shield)
        case .frost:
            enemyFrozen = true
            pushMessage("Frost! Enemy frozen", GQBTheme.mana)
        }
        if enemyHP <= 0 {
            phase = .resolving
            finishVictory()
        } else {
            phase = .resolving
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.runEnemyTurn()
            }
        }
    }

    func useUltimate() {
        guard canUltimate else { return }
        ultimate = 0
        let dmg = 40 + store.save.heroLevel * 5 + heroAttackBonus * 3
        dealDamageToEnemy(dmg)
        let heal = 20 + store.save.heroLevel * 2
        heroHP = min(heroHP + heal, heroMaxHP)
        pushMessage("ULTIMATE \(dmg)!", GQBTheme.ultimate)
        if enemyHP <= 0 {
            phase = .resolving
            finishVictory()
        } else {
            phase = .resolving
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.runEnemyTurn()
            }
        }
    }

    // MARK: - Enemy turn

    private func planEnemyIntent() {
        // Decide the next action deterministically based on behavior + counter.
        var rng = GemQuestSeededRNG(seed: gemQuestMixSeed(battle.globalIndex, enemyTurnCounter, 99))
        let scaledAtk = battle.baseAttack + berserkRamp + stackerBonus
        switch battle.behavior {
        case .striker:
            enemyIntent = .attack(scaledAtk)
        case .armored:
            enemyIntent = rng.chance(0.25) ? .shieldUp : .attack(scaledAtk)
        case .healer:
            enemyIntent = (enemyHP < enemyMaxHP / 2 && rng.chance(0.5)) ? .heal : .attack(scaledAtk)
        case .poisoner:
            enemyIntent = rng.chance(0.4) ? .poison : .attack(scaledAtk)
        case .berserker:
            enemyIntent = rng.chance(0.3) ? .enrage : .attack(scaledAtk)
        case .shielder:
            enemyIntent = rng.chance(0.4) ? .shieldUp : .attack(scaledAtk)
        case .stacker:
            enemyIntent = .attack(scaledAtk)
        case .tank:
            enemyIntent = rng.chance(0.2) ? .shieldUp : .attack(scaledAtk)
        }
    }

    private func runEnemyTurn() {
        guard phase == .resolving else { return }
        phase = .enemyTurn

        // Poison ticks first.
        if enemyPoisonStacks > 0 {
            // Poison is applied TO the enemy by... no — poisoner enemy poisons the HERO.
        }

        if enemyFrozen {
            enemyFrozen = false
            pushMessage("\(battle.enemyName) is frozen!", GQBTheme.mana)
            endEnemyTurn()
            return
        }

        enemyTurnCounter += 1

        switch enemyIntent {
        case .attack(let amount):
            applyEnemyDamage(amount)
            if battle.behavior == .stacker { stackerBonus += 2 }
        case .heal:
            let heal = max(8, enemyMaxHP / 10)
            enemyHP = min(enemyMaxHP, enemyHP + heal)
            pushMessage("\(battle.enemyName) heals \(heal)", GQBTheme.poison)
        case .shieldUp:
            let block = 6 + battle.regionIndex * 2
            enemyShield += block
            pushMessage("\(battle.enemyName) guards +\(block)", GQBTheme.shield)
        case .poison:
            heroPoisonStacks += 2
            pushMessage("Poisoned! (\(heroPoisonStacks))", GQBTheme.poison)
            applyEnemyDamage(max(1, battle.baseAttack / 2))
        case .enrage:
            berserkRamp += 3
            pushMessage("\(battle.enemyName) enrages!", GQBTheme.danger)
            applyEnemyDamage(battle.baseAttack)
        case .bossPhase:
            applyEnemyDamage(battle.baseAttack)
        }

        // Hero poison damage at end of enemy action.
        if heroPoisonStacks > 0 {
            let pd = heroPoisonStacks
            heroHP = max(0, heroHP - pd)
            damageTaken += pd
            heroPoisonStacks = max(0, heroPoisonStacks - 1)
            pushMessage("Venom \(pd)", GQBTheme.poison)
        }

        if heroHP <= 0 {
            finishDefeat()
            return
        }
        endEnemyTurn()
    }

    @Published var heroPoisonStacks: Int = 0

    private func applyEnemyDamage(_ amount: Int) {
        var dmg = amount
        if heroShield > 0 {
            let absorbed = min(heroShield, dmg)
            heroShield -= absorbed
            dmg -= absorbed
        }
        if dmg > 0 {
            heroHP = max(0, heroHP - dmg)
            damageTaken += dmg
            pushMessage("\(battle.enemyName) hits \(dmg)", GQBTheme.danger)
        } else {
            pushMessage("Blocked!", GQBTheme.shield)
        }
    }

    private func endEnemyTurn() {
        planEnemyIntent()
        if heroHP <= 0 {
            finishDefeat()
        } else {
            phase = .playerTurn
            // Mark onboarding completed once the player has made it through a full turn.
            if !store.save.onboardingDone {
                store.save.onboardingDone = true
            }
        }
    }

    // MARK: - Resolution

    private func finishVictory() {
        // Star rating: 3 stars baseline, lose stars for heavy damage / many turns.
        var stars = 3
        let hpFrac = Double(heroHP) / Double(max(1, heroMaxHP))
        if hpFrac < 0.5 { stars -= 1 }
        if hpFrac < 0.2 { stars -= 1 }
        stars = max(1, stars)

        earnedStars = stars
        let baseCoins = 18 + battle.globalIndex * 3 + (battle.isBoss ? 60 : 0)
        earnedCoins = baseCoins + coinsCollected
        let beforeXP = store.save.heroXP
        leveledUp = store.recordVictory(battle: battle, stars: stars, coinsEarned: earnedCoins)
        earnedXP = store.save.heroXP - beforeXP
        if !store.save.onboardingDone { store.save.onboardingDone = true }
        phase = .victory
    }

    private func finishDefeat() {
        // Seeing the enemy still adds it to the bestiary.
        if !store.save.unlockedEnemies.contains(battle.behavior.rawValue) {
            store.save.unlockedEnemies.append(battle.behavior.rawValue)
        }
        phase = .defeat
    }

    func dismissOnboardingHint() {
        phase = .playerTurn
    }
}
