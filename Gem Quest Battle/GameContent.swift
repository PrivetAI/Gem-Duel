import SwiftUI

// MARK: - Enemy archetypes (8 behaviors)

enum EnemyBehavior: Int, Codable, CaseIterable {
    case striker = 0   // basic, steady attack
    case armored       // high block, lower attack
    case healer        // heals itself sometimes
    case poisoner      // applies poison
    case berserker     // ramps damage each turn
    case shielder      // raises its own block
    case stacker       // attack grows when it lands hits
    case tank          // huge HP, slow

    var displayName: String {
        switch self {
        case .striker: return "Striker"
        case .armored: return "Armored Brute"
        case .healer: return "Mender"
        case .poisoner: return "Venomweaver"
        case .berserker: return "Berserker"
        case .shielder: return "Bulwark"
        case .stacker: return "Bloodletter"
        case .tank: return "Stone Tank"
        }
    }

    var lore: String {
        switch self {
        case .striker: return "A relentless foe that strikes with simple, steady blows."
        case .armored: return "Plated in heavy steel — its guard absorbs much of your damage."
        case .healer: return "Channels dark vigor to mend its own wounds mid-battle."
        case .poisoner: return "Coats its strikes in venom that gnaws each turn."
        case .berserker: return "Grows angrier — and deadlier — the longer the fight drags."
        case .shielder: return "Conjures barriers to blunt the bite of your gems."
        case .stacker: return "Every landed hit feeds its frenzy, stacking ever more power."
        case .tank: return "A mountain of HP. Patience and cascades will wear it down."
        }
    }
}

// MARK: - Region (5 regions x 12 battles = 60 battles; every 12th is a boss)

struct Region: Identifiable {
    let id: Int
    let name: String
    let tint: Color
    let bossName: String

    static let all: [Region] = [
        Region(id: 0, name: "Amber Hollow", tint: Color(red: 0.85, green: 0.62, blue: 0.28), bossName: "Gildmaw the Hoarder"),
        Region(id: 1, name: "Sapphire Reach", tint: Color(red: 0.35, green: 0.55, blue: 0.90), bossName: "Frostspire Sentinel"),
        Region(id: 2, name: "Crimson Verge", tint: Color(red: 0.82, green: 0.30, blue: 0.34), bossName: "Emberlord Vaskar"),
        Region(id: 3, name: "Verdant Mire", tint: Color(red: 0.42, green: 0.72, blue: 0.40), bossName: "The Rotbloom Hydra"),
        Region(id: 4, name: "Obsidian Spire", tint: Color(red: 0.55, green: 0.40, blue: 0.85), bossName: "Nyxara, Gem Eternal")
    ]
}

// MARK: - Battle definition (computed per node index 0..59)

struct BattleDef: Identifiable {
    var id: Int { globalIndex }
    let globalIndex: Int    // 0..59
    let regionIndex: Int    // 0..4
    let localIndex: Int     // 0..11
    let isBoss: Bool
    let enemyName: String
    let behavior: EnemyBehavior
    let enemyMaxHP: Int
    let baseAttack: Int
    let enemyBlock: Int     // starting block for armored types

    static func make(global: Int) -> BattleDef {
        let region = global / 12
        let local = global % 12
        let isBoss = (local == 11)
        // Behavior cycles through archetypes; bosses are region-flavored.
        let behavior: EnemyBehavior
        if isBoss {
            switch region {
            case 0: behavior = .stacker
            case 1: behavior = .shielder
            case 2: behavior = .berserker
            case 3: behavior = .poisoner
            default: behavior = .tank
            }
        } else {
            behavior = EnemyBehavior.allCases[local % EnemyBehavior.allCases.count]
        }
        // Scaling: rises across both region and local index.
        let tier = Double(region) * 12.0 + Double(local)
        let hp = Int(28.0 + tier * 6.2 + (isBoss ? 140.0 : 0.0) + Double(region * region) * 4.0)
        let atk = Int(5.0 + tier * 0.85 + (isBoss ? 6.0 : 0.0) + Double(region) * 1.5)
        var block = 0
        if behavior == .armored { block = 6 + region * 3 }
        if behavior == .shielder { block = 4 + region * 2 }
        let name: String
        if isBoss {
            name = Region.all[region].bossName
        } else {
            name = behavior.displayName
        }
        return BattleDef(globalIndex: global, regionIndex: region, localIndex: local,
                         isBoss: isBoss, enemyName: name, behavior: behavior,
                         enemyMaxHP: hp, baseAttack: atk, enemyBlock: block)
    }
}

// MARK: - Spells (charged by Mana)

enum SpellKind: Int, Codable, CaseIterable {
    case fireball = 0   // AoE / heavy damage
    case mend           // big heal
    case earthwall      // big shield
    case frost          // skip enemy turn

    var name: String {
        switch self {
        case .fireball: return "Fireball"
        case .mend: return "Mend"
        case .earthwall: return "Earthwall"
        case .frost: return "Frost"
        }
    }
    var manaCost: Int {
        switch self {
        case .fireball: return 14
        case .mend: return 12
        case .earthwall: return 10
        case .frost: return 16
        }
    }
    var desc: String {
        switch self {
        case .fireball: return "Unleash a fireball for heavy damage."
        case .mend: return "Mend a large amount of health."
        case .earthwall: return "Raise a wall of stone for big block."
        case .frost: return "Freeze the foe — it skips its next turn."
        }
    }
    // Hero level at which the spell unlocks.
    var unlockLevel: Int {
        switch self {
        case .fireball: return 1
        case .earthwall: return 2
        case .mend: return 3
        case .frost: return 4
        }
    }
}

// MARK: - Gear

enum GearSlot: Int, Codable, CaseIterable {
    case weapon = 0, armor, charm
    var name: String {
        switch self {
        case .weapon: return "Weapon"
        case .armor: return "Armor"
        case .charm: return "Charm"
        }
    }
}

struct GearItem: Identifiable {
    let id: Int                 // stable id
    let slot: GearSlot
    let tier: Int               // 0..3
    let name: String
    let cost: Int
    // Passive bonuses
    let bonusAttack: Int        // weapon: extra sword damage
    let bonusMaxHP: Int         // armor: extra max HP
    let bonusBlockPerShield: Int// armor: extra block per shield gem
    let bonusManaPerGem: Int    // charm: extra mana per mana gem
    let bonusCoinPerGem: Int    // charm: extra coins per coin gem

    static let catalog: [GearItem] = {
        var items: [GearItem] = []
        var id = 0
        // Weapons
        let weaponNames = ["Iron Edge", "Steel Talon", "Runed Saber", "Dragontooth Blade"]
        for t in 0..<4 {
            items.append(GearItem(id: id, slot: .weapon, tier: t, name: weaponNames[t],
                                  cost: t == 0 ? 0 : 60 * t * t + 40,
                                  bonusAttack: t * 3, bonusMaxHP: 0, bonusBlockPerShield: 0,
                                  bonusManaPerGem: 0, bonusCoinPerGem: 0)); id += 1
        }
        // Armor
        let armorNames = ["Cloth Wrap", "Chain Vest", "Plated Hauberk", "Aegis Carapace"]
        for t in 0..<4 {
            items.append(GearItem(id: id, slot: .armor, tier: t, name: armorNames[t],
                                  cost: t == 0 ? 0 : 70 * t * t + 40,
                                  bonusAttack: 0, bonusMaxHP: t * 14, bonusBlockPerShield: t,
                                  bonusManaPerGem: 0, bonusCoinPerGem: 0)); id += 1
        }
        // Charms
        let charmNames = ["Copper Trinket", "Amber Sigil", "Arcane Locket", "Eternal Prism"]
        for t in 0..<4 {
            items.append(GearItem(id: id, slot: .charm, tier: t, name: charmNames[t],
                                  cost: t == 0 ? 0 : 65 * t * t + 40,
                                  bonusAttack: 0, bonusMaxHP: 0, bonusBlockPerShield: 0,
                                  bonusManaPerGem: t, bonusCoinPerGem: t)); id += 1
        }
        return items
    }()

    static func item(id: Int) -> GearItem { catalog.first { $0.id == id } ?? catalog[0] }
    static func items(for slot: GearSlot) -> [GearItem] { catalog.filter { $0.slot == slot } }

    var bonusSummary: String {
        var parts: [String] = []
        if bonusAttack > 0 { parts.append("+\(bonusAttack) sword dmg") }
        if bonusMaxHP > 0 { parts.append("+\(bonusMaxHP) max HP") }
        if bonusBlockPerShield > 0 { parts.append("+\(bonusBlockPerShield) block/shield") }
        if bonusManaPerGem > 0 { parts.append("+\(bonusManaPerGem) mana/gem") }
        if bonusCoinPerGem > 0 { parts.append("+\(bonusCoinPerGem) coin/gem") }
        return parts.isEmpty ? "Basic starter gear" : parts.joined(separator: ", ")
    }
}
