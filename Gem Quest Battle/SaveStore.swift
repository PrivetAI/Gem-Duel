import Foundation
import Combine

// Codable save model persisted to UserDefaults under the gqb.* namespace.
// All decode sites use decodeIfPresent ?? default.

struct GQBSave: Codable {
    var starsByBattle: [Int: Int]      // global battle index -> stars (0..3)
    var heroLevel: Int
    var heroXP: Int
    var coins: Int
    var ownedGearIDs: [Int]
    var equippedWeaponID: Int
    var equippedArmorID: Int
    var equippedCharmID: Int
    var unlockedEnemies: [Int]         // EnemyBehavior rawValues seen
    var unlockedBosses: [Int]          // region indices whose boss is beaten
    var soundOn: Bool
    var hapticsOn: Bool
    var onboardingDone: Bool

    static var fresh: GQBSave {
        GQBSave(
            starsByBattle: [:],
            heroLevel: 1,
            heroXP: 0,
            coins: 0,
            ownedGearIDs: [0, 4, 8],   // tier-0 starters of each slot
            equippedWeaponID: 0,
            equippedArmorID: 4,
            equippedCharmID: 8,
            unlockedEnemies: [],
            unlockedBosses: [],
            soundOn: true,
            hapticsOn: true,
            onboardingDone: false
        )
    }

    // Custom decoding so missing keys fall back to defaults.
    enum CodingKeys: String, CodingKey {
        case starsByBattle, heroLevel, heroXP, coins, ownedGearIDs
        case equippedWeaponID, equippedArmorID, equippedCharmID
        case unlockedEnemies, unlockedBosses, soundOn, hapticsOn, onboardingDone
    }

    init(starsByBattle: [Int: Int], heroLevel: Int, heroXP: Int, coins: Int,
         ownedGearIDs: [Int], equippedWeaponID: Int, equippedArmorID: Int,
         equippedCharmID: Int, unlockedEnemies: [Int], unlockedBosses: [Int],
         soundOn: Bool, hapticsOn: Bool, onboardingDone: Bool) {
        self.starsByBattle = starsByBattle
        self.heroLevel = heroLevel
        self.heroXP = heroXP
        self.coins = coins
        self.ownedGearIDs = ownedGearIDs
        self.equippedWeaponID = equippedWeaponID
        self.equippedArmorID = equippedArmorID
        self.equippedCharmID = equippedCharmID
        self.unlockedEnemies = unlockedEnemies
        self.unlockedBosses = unlockedBosses
        self.soundOn = soundOn
        self.hapticsOn = hapticsOn
        self.onboardingDone = onboardingDone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GQBSave.fresh
        // starsByBattle stored as [String:Int] for JSON compatibility.
        if let raw = try c.decodeIfPresent([String: Int].self, forKey: .starsByBattle) {
            var map: [Int: Int] = [:]
            for (k, v) in raw { if let ki = Int(k) { map[ki] = v } }
            starsByBattle = map
        } else { starsByBattle = d.starsByBattle }
        heroLevel = try c.decodeIfPresent(Int.self, forKey: .heroLevel) ?? d.heroLevel
        heroXP = try c.decodeIfPresent(Int.self, forKey: .heroXP) ?? d.heroXP
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? d.coins
        ownedGearIDs = try c.decodeIfPresent([Int].self, forKey: .ownedGearIDs) ?? d.ownedGearIDs
        equippedWeaponID = try c.decodeIfPresent(Int.self, forKey: .equippedWeaponID) ?? d.equippedWeaponID
        equippedArmorID = try c.decodeIfPresent(Int.self, forKey: .equippedArmorID) ?? d.equippedArmorID
        equippedCharmID = try c.decodeIfPresent(Int.self, forKey: .equippedCharmID) ?? d.equippedCharmID
        unlockedEnemies = try c.decodeIfPresent([Int].self, forKey: .unlockedEnemies) ?? d.unlockedEnemies
        unlockedBosses = try c.decodeIfPresent([Int].self, forKey: .unlockedBosses) ?? d.unlockedBosses
        soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? d.soundOn
        hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? d.hapticsOn
        onboardingDone = try c.decodeIfPresent(Bool.self, forKey: .onboardingDone) ?? d.onboardingDone
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        var strMap: [String: Int] = [:]
        for (k, v) in starsByBattle { strMap[String(k)] = v }
        try c.encode(strMap, forKey: .starsByBattle)
        try c.encode(heroLevel, forKey: .heroLevel)
        try c.encode(heroXP, forKey: .heroXP)
        try c.encode(coins, forKey: .coins)
        try c.encode(ownedGearIDs, forKey: .ownedGearIDs)
        try c.encode(equippedWeaponID, forKey: .equippedWeaponID)
        try c.encode(equippedArmorID, forKey: .equippedArmorID)
        try c.encode(equippedCharmID, forKey: .equippedCharmID)
        try c.encode(unlockedEnemies, forKey: .unlockedEnemies)
        try c.encode(unlockedBosses, forKey: .unlockedBosses)
        try c.encode(soundOn, forKey: .soundOn)
        try c.encode(hapticsOn, forKey: .hapticsOn)
        try c.encode(onboardingDone, forKey: .onboardingDone)
    }
}

final class SaveStore: ObservableObject {
    @Published var save: GQBSave {
        didSet { persist() }
    }

    private let key = "gqb.save.v1"

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(GQBSave.self, from: data) {
            save = decoded
        } else {
            save = GQBSave.fresh
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(save) {
            UserDefaults.standard.set(data, forKey: "gqb.save.v1")
        }
    }

    func resetAll() {
        save = GQBSave.fresh
    }

    // MARK: - Hero derived stats

    // XP required to reach a given level.
    func xpForLevel(_ level: Int) -> Int {
        // Level 1 -> 0, level 2 -> 60, growing.
        if level <= 1 { return 0 }
        return 40 * (level - 1) * level / 2 + 20 * (level - 1)
    }

    var heroMaxHP: Int {
        let base = 80 + (save.heroLevel - 1) * 14
        let gear = GearItem.item(id: save.equippedArmorID).bonusMaxHP
        return base + gear
    }

    var heroAttackBonus: Int {
        let base = (save.heroLevel - 1) * 1  // small base attack scaling
        let gear = GearItem.item(id: save.equippedWeaponID).bonusAttack
        return base + gear
    }

    var equippedWeapon: GearItem { GearItem.item(id: save.equippedWeaponID) }
    var equippedArmor: GearItem { GearItem.item(id: save.equippedArmorID) }
    var equippedCharm: GearItem { GearItem.item(id: save.equippedCharmID) }

    func unlockedSpells() -> [SpellKind] {
        SpellKind.allCases.filter { save.heroLevel >= $0.unlockLevel }
    }

    // MARK: - Progression helpers

    func stars(for battle: Int) -> Int { save.starsByBattle[battle] ?? 0 }

    func isBattleUnlocked(_ global: Int) -> Bool {
        if global == 0 { return true }
        // A battle is unlocked if the previous one has at least 1 star.
        return stars(for: global - 1) >= 1
    }

    func isRegionUnlocked(_ region: Int) -> Bool {
        if region == 0 { return true }
        // Region unlocks when prior region's boss (local 11) beaten.
        return stars(for: region * 12 - 1) >= 1
    }

    var totalStars: Int { save.starsByBattle.values.reduce(0, +) }

    // Award results from a finished battle. Returns level-ups gained.
    @discardableResult
    func recordVictory(battle: BattleDef, stars: Int, coinsEarned: Int) -> Int {
        let prev = save.starsByBattle[battle.globalIndex] ?? 0
        if stars > prev { save.starsByBattle[battle.globalIndex] = stars }
        save.coins += coinsEarned
        // Bestiary
        if !save.unlockedEnemies.contains(battle.behavior.rawValue) {
            save.unlockedEnemies.append(battle.behavior.rawValue)
        }
        if battle.isBoss && !save.unlockedBosses.contains(battle.regionIndex) {
            save.unlockedBosses.append(battle.regionIndex)
        }
        // XP — bigger for higher battles & bosses.
        let xpGain = 30 + battle.globalIndex * 6 + (battle.isBoss ? 120 : 0) + stars * 10
        save.heroXP += xpGain
        var levelUps = 0
        while save.heroXP >= xpForLevel(save.heroLevel + 1) {
            save.heroLevel += 1
            levelUps += 1
        }
        return levelUps
    }

    func buy(_ item: GearItem) -> Bool {
        guard !save.ownedGearIDs.contains(item.id) else { return false }
        guard save.coins >= item.cost else { return false }
        save.coins -= item.cost
        save.ownedGearIDs.append(item.id)
        return true
    }

    func owns(_ item: GearItem) -> Bool { save.ownedGearIDs.contains(item.id) }

    func equip(_ item: GearItem) {
        guard owns(item) else { return }
        switch item.slot {
        case .weapon: save.equippedWeaponID = item.id
        case .armor: save.equippedArmorID = item.id
        case .charm: save.equippedCharmID = item.id
        }
    }

    func isEquipped(_ item: GearItem) -> Bool {
        switch item.slot {
        case .weapon: return save.equippedWeaponID == item.id
        case .armor: return save.equippedArmorID == item.id
        case .charm: return save.equippedCharmID == item.id
        }
    }
}
