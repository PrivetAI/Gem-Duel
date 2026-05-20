import SwiftUI

// Fantasy-jewel palette: deep plum / midnight backgrounds, gold UI, jewel-tone gems.
enum GQBTheme {
    // Backgrounds
    static let bgDeep = Color(red: 0.07, green: 0.05, blue: 0.13)      // midnight plum
    static let bgMid = Color(red: 0.13, green: 0.09, blue: 0.22)       // plum
    static let panel = Color(red: 0.18, green: 0.13, blue: 0.29)       // raised panel
    static let panelHi = Color(red: 0.24, green: 0.18, blue: 0.38)     // hover/active panel
    static let cardStroke = Color(red: 0.40, green: 0.30, blue: 0.58)

    // Gold UI accents
    static let gold = Color(red: 0.93, green: 0.78, blue: 0.36)
    static let goldDim = Color(red: 0.66, green: 0.54, blue: 0.27)
    static let goldDeep = Color(red: 0.45, green: 0.35, blue: 0.16)

    // Text
    static let text = Color(red: 0.96, green: 0.93, blue: 0.99)
    static let textDim = Color(red: 0.72, green: 0.67, blue: 0.82)
    static let textFaint = Color(red: 0.52, green: 0.47, blue: 0.62)

    // Status
    static let hp = Color(red: 0.86, green: 0.27, blue: 0.36)
    static let mana = Color(red: 0.30, green: 0.55, blue: 0.95)
    static let shield = Color(red: 0.55, green: 0.78, blue: 0.92)
    static let ultimate = Color(red: 0.95, green: 0.82, blue: 0.30)
    static let xp = Color(red: 0.55, green: 0.85, blue: 0.45)
    static let danger = Color(red: 0.91, green: 0.36, blue: 0.32)
    static let poison = Color(red: 0.55, green: 0.78, blue: 0.34)
}

// Gem visual identity: each gem has a distinct color AND a distinct shape for accessibility.
enum GemKind: Int, CaseIterable, Codable {
    case sword = 0   // damage enemy   — blade
    case shield      // add block      — shield
    case heart       // heal hero      — heart
    case mana        // charge spells  — teardrop
    case coin        // earn coins     — disc
    case star        // charge ultimate— star

    var color: Color {
        switch self {
        case .sword:  return Color(red: 0.86, green: 0.30, blue: 0.34)   // ruby red
        case .shield: return Color(red: 0.36, green: 0.62, blue: 0.92)   // sapphire blue
        case .heart:  return Color(red: 0.95, green: 0.45, blue: 0.66)   // rose pink
        case .mana:   return Color(red: 0.55, green: 0.40, blue: 0.92)   // amethyst purple
        case .coin:   return Color(red: 0.95, green: 0.78, blue: 0.30)   // topaz gold
        case .star:   return Color(red: 0.40, green: 0.86, blue: 0.74)   // emerald teal
        }
    }

    var colorDark: Color {
        let c = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return Color(red: Double(r) * 0.55, green: Double(g) * 0.55, blue: Double(b) * 0.55)
    }

    var name: String {
        switch self {
        case .sword:  return "Sword"
        case .shield: return "Shield"
        case .heart:  return "Heart"
        case .mana:   return "Mana"
        case .coin:   return "Coin"
        case .star:   return "Star"
        }
    }

    var effectText: String {
        switch self {
        case .sword:  return "Strikes the enemy for damage."
        case .shield: return "Raises block to absorb the next hits."
        case .heart:  return "Restores your hero's health."
        case .mana:   return "Charges your spells."
        case .coin:   return "Earns coins for the shop."
        case .star:   return "Charges your ultimate meter."
        }
    }
}
