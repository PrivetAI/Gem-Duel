import SwiftUI

// All art is built from custom SwiftUI Shapes — no SF Symbols, no emoji, no system images.

// MARK: - Gem Shapes (each gem type has a distinct silhouette)

struct BladeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX
        // Diamond blade with a small crossguard.
        p.move(to: CGPoint(x: cx, y: rect.minY + h * 0.04))
        p.addLine(to: CGPoint(x: cx + w * 0.18, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: cx + w * 0.10, y: rect.minY + h * 0.68))
        p.addLine(to: CGPoint(x: cx + w * 0.30, y: rect.minY + h * 0.70))
        p.addLine(to: CGPoint(x: cx + w * 0.10, y: rect.minY + h * 0.78))
        p.addLine(to: CGPoint(x: cx + w * 0.06, y: rect.maxY - h * 0.04))
        p.addLine(to: CGPoint(x: cx - w * 0.06, y: rect.maxY - h * 0.04))
        p.addLine(to: CGPoint(x: cx - w * 0.10, y: rect.minY + h * 0.78))
        p.addLine(to: CGPoint(x: cx - w * 0.30, y: rect.minY + h * 0.70))
        p.addLine(to: CGPoint(x: cx - w * 0.10, y: rect.minY + h * 0.68))
        p.addLine(to: CGPoint(x: cx - w * 0.18, y: rect.minY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.18))
        p.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.7),
                   control2: CGPoint(x: rect.minX + w * 0.72, y: rect.maxY - h * 0.05))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.18),
                   control1: CGPoint(x: rect.minX + w * 0.28, y: rect.maxY - h * 0.05),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.7))
        p.closeSubpath()
        return p
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.92))
        p.addCurve(to: CGPoint(x: rect.minX, y: rect.minY + h * 0.28),
                   control1: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.70),
                   control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.50))
        p.addArc(center: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.28),
                 radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(center: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + h * 0.28),
                 radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.92),
                   control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.50),
                   control2: CGPoint(x: rect.minX + w * 0.70, y: rect.minY + h * 0.70))
        p.closeSubpath()
        return p
    }
}

struct TeardropShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.66),
                   control1: CGPoint(x: rect.midX + w * 0.15, y: rect.minY + h * 0.22),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.42))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + h * 0.66),
                 radius: w * 0.5, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.42),
                   control2: CGPoint(x: rect.midX - w * 0.15, y: rect.minY + h * 0.22))
        p.closeSubpath()
        return p
    }
}

struct DiscShape: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.04
        return Path(ellipseIn: rect.insetBy(dx: inset, dy: inset))
    }
}

struct StarShape: Shape {
    var points: Int = 5
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.46
        let step = Double.pi / Double(points)
        var angle = -Double.pi / 2
        for i in 0..<(points * 2) {
            let r = (i % 2 == 0) ? outer : inner
            let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * r,
                             y: center.y + CGFloat(sin(angle)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            angle += step
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Gem View (color + shape + facet sheen + optional special overlay)

enum GemSpecial: Int, Codable {
    case none = 0
    case lineH      // clears a row
    case lineV      // clears a column
    case bomb       // clears 3x3
}

struct GemView: View {
    let kind: GemKind
    var special: GemSpecial = .none
    var selected: Bool = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // Rounded gem base
                RoundedRectangle(cornerRadius: s * 0.22)
                    .fill(
                        LinearGradient(colors: [kind.color, kind.colorDark],
                                       startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: s * 0.22)
                            .stroke(Color.white.opacity(0.25), lineWidth: s * 0.04)
                    )
                // Sheen highlight
                RoundedRectangle(cornerRadius: s * 0.18)
                    .fill(Color.white.opacity(0.16))
                    .frame(width: s * 0.4, height: s * 0.18)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -s * 0.15, y: -s * 0.22)
                // Distinct shape mark
                gemShape
                    .frame(width: s * 0.5, height: s * 0.5)
                    .shadow(color: kind.colorDark.opacity(0.6), radius: 1, x: 0, y: 1)
                // Special overlay marker
                specialOverlay(s: s)
            }
            .frame(width: s, height: s)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: s * 0.22)
                    .stroke(GQBTheme.gold, lineWidth: selected ? s * 0.10 : 0)
            )
            .scaleEffect(selected ? 1.06 : 1.0)
        }
    }

    @ViewBuilder private var gemShape: some View {
        let fillColor = Color.white.opacity(0.9)
        switch kind {
        case .sword:  BladeShape().fill(fillColor)
        case .shield: ShieldShape().fill(fillColor)
        case .heart:  HeartShape().fill(fillColor)
        case .mana:   TeardropShape().fill(fillColor)
        case .coin:   DiscShape().fill(fillColor).overlay(DiscShape().stroke(kind.colorDark, lineWidth: 2).padding(4))
        case .star:   StarShape().fill(fillColor)
        }
    }

    @ViewBuilder private func specialOverlay(s: CGFloat) -> some View {
        switch special {
        case .none:
            EmptyView()
        case .lineH:
            Rectangle().fill(Color.white.opacity(0.85)).frame(width: s * 0.78, height: s * 0.07)
        case .lineV:
            Rectangle().fill(Color.white.opacity(0.85)).frame(width: s * 0.07, height: s * 0.78)
        case .bomb:
            Circle().stroke(Color.white.opacity(0.9), lineWidth: s * 0.06)
                .frame(width: s * 0.72, height: s * 0.72)
        }
    }
}

// MARK: - Hero / Enemy silhouettes

struct HeroMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Head
        p.addEllipse(in: CGRect(x: rect.midX - w * 0.16, y: rect.minY + h * 0.06,
                                width: w * 0.32, height: h * 0.30))
        // Body / cloak (pointed shoulders)
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.34))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.10, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.22, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.22, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.10, y: rect.minY + h * 0.55))
        p.closeSubpath()
        return p
    }
}

struct EnemyMarkShape: Shape {
    // Jagged, horned silhouette to contrast hero.
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Horns
        p.move(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.22))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.30, y: rect.minY + h * 0.22))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.18, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.10, y: rect.minY + h * 0.40))
        // Body
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.04, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX + w * 0.12, y: rect.maxY - h * 0.10))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX - w * 0.12, y: rect.maxY - h * 0.10))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.04, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.10, y: rect.minY + h * 0.40))
        p.closeSubpath()
        return p
    }
}

// MARK: - Spell glyphs

struct FireballGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY),
                   control1: CGPoint(x: rect.midX + w * 0.30, y: rect.minY + h * 0.10),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.25))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.midY + h * 0.05),
                 radius: w * 0.45, startAngle: .degrees(-20), endAngle: .degrees(200), clockwise: false)
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.minY),
                   control1: CGPoint(x: rect.minX + w * 0.05, y: rect.minY + h * 0.20),
                   control2: CGPoint(x: rect.midX - w * 0.25, y: rect.minY + h * 0.08))
        p.closeSubpath()
        return p
    }
}

struct MendGlyph: Shape {
    // Plus / cross within heart-ish frame.
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let t = w * 0.26
        p.addRoundedRect(in: CGRect(x: rect.midX - t/2, y: rect.minY + h * 0.10,
                                    width: t, height: h * 0.8), cornerSize: CGSize(width: 3, height: 3))
        p.addRoundedRect(in: CGRect(x: rect.minX + w * 0.10, y: rect.midY - t/2,
                                    width: w * 0.8, height: t), cornerSize: CGSize(width: 3, height: 3))
        return p
    }
}

struct EarthwallGlyph: Shape {
    // Brick wall block.
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRect(CGRect(x: rect.minX + w * 0.08, y: rect.minY + h * 0.18, width: w * 0.84, height: h * 0.64))
        // mortar lines
        p.move(to: CGPoint(x: rect.minX + w * 0.08, y: rect.midY)); p.addLine(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.midY))
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.18)); p.addLine(to: CGPoint(x: rect.midX, y: rect.midY))
        p.move(to: CGPoint(x: rect.minX + w * 0.30, y: rect.midY)); p.addLine(to: CGPoint(x: rect.minX + w * 0.30, y: rect.maxY - h * 0.18))
        p.move(to: CGPoint(x: rect.maxX - w * 0.30, y: rect.midY)); p.addLine(to: CGPoint(x: rect.maxX - w * 0.30, y: rect.maxY - h * 0.18))
        return p
    }
}

struct FrostGlyph: Shape {
    // Six-spoke snowflake.
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) * 0.45
        for i in 0..<6 {
            let a = Double(i) * Double.pi / 3.0
            let tip = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            p.move(to: c); p.addLine(to: tip)
            // small branches
            let mid = CGPoint(x: c.x + CGFloat(cos(a)) * r * 0.6, y: c.y + CGFloat(sin(a)) * r * 0.6)
            let b1 = CGPoint(x: mid.x + CGFloat(cos(a + 0.6)) * r * 0.22, y: mid.y + CGFloat(sin(a + 0.6)) * r * 0.22)
            let b2 = CGPoint(x: mid.x + CGFloat(cos(a - 0.6)) * r * 0.22, y: mid.y + CGFloat(sin(a - 0.6)) * r * 0.22)
            p.move(to: mid); p.addLine(to: b1)
            p.move(to: mid); p.addLine(to: b2)
        }
        return p
    }
}

// MARK: - UI glyphs (no SF Symbols)

struct ChevronLeftShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return p
    }
}

struct GearGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) * 0.5
        let inner = outer * 0.7
        let teeth = 8
        let step = Double.pi / Double(teeth)
        var a = -Double.pi / 2
        for i in 0..<(teeth * 2) {
            let r = (i % 2 == 0) ? outer : inner
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            a += step
        }
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: c.x - outer * 0.32, y: c.y - outer * 0.32, width: outer * 0.64, height: outer * 0.64))
        return p
    }
}

struct MapPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX + w * 0.5, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.45),
                   control2: CGPoint(x: rect.minX + w * 0.10, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX - w * 0.10, y: rect.minY),
                   control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.45))
        p.closeSubpath()
        return p
    }
}

struct LockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // shackle
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + h * 0.34),
                 radius: w * 0.24, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        // body
        p.addRoundedRect(in: CGRect(x: rect.minX + w * 0.16, y: rect.minY + h * 0.38,
                                    width: w * 0.68, height: h * 0.56),
                         cornerSize: CGSize(width: w * 0.08, height: w * 0.08))
        return p
    }
}

struct SwordCrossGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.1, y: rect.minY + h * 0.1))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.1, y: rect.maxY - h * 0.1))
        p.move(to: CGPoint(x: rect.maxX - w * 0.1, y: rect.minY + h * 0.1))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.1, y: rect.maxY - h * 0.1))
        return p
    }
}

struct BagGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: rect.minX + w * 0.12, y: rect.minY + h * 0.30,
                                    width: w * 0.76, height: h * 0.62),
                         cornerSize: CGSize(width: w * 0.16, height: w * 0.16))
        p.move(to: CGPoint(x: rect.minX + w * 0.32, y: rect.minY + h * 0.34))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + h * 0.34), radius: w * 0.18,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return p
    }
}

struct BookGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRect(CGRect(x: rect.minX + w * 0.14, y: rect.minY + h * 0.14, width: w * 0.72, height: h * 0.72))
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.14)); p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.14))
        p.move(to: CGPoint(x: rect.minX + w * 0.26, y: rect.minY + h * 0.36)); p.addLine(to: CGPoint(x: rect.minX + w * 0.42, y: rect.minY + h * 0.36))
        p.move(to: CGPoint(x: rect.minX + w * 0.58, y: rect.minY + h * 0.36)); p.addLine(to: CGPoint(x: rect.maxX - w * 0.26, y: rect.minY + h * 0.36))
        return p
    }
}

struct CrownGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.08, y: rect.maxY - h * 0.12))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.18, y: rect.minY + h * 0.30))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.34, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.18))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.34, y: rect.minY + h * 0.55))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.18, y: rect.minY + h * 0.30))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.maxY - h * 0.12))
        p.closeSubpath()
        return p
    }
}

struct PotionGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRect(CGRect(x: rect.midX - w * 0.10, y: rect.minY + h * 0.06, width: w * 0.20, height: h * 0.22))
        p.move(to: CGPoint(x: rect.midX - w * 0.10, y: rect.minY + h * 0.28))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.18, y: rect.maxY - h * 0.18))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.maxY - h * 0.30), radius: w * 0.34,
                 startAngle: .degrees(140), endAngle: .degrees(40), clockwise: false)
        p.addLine(to: CGPoint(x: rect.midX + w * 0.10, y: rect.minY + h * 0.28))
        p.closeSubpath()
        return p
    }
}

// MARK: - Gear glyphs

struct WeaponGearGlyph: Shape {
    func path(in rect: CGRect) -> Path { BladeShape().path(in: rect) }
}
struct ArmorGearGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // breastplate
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.08))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.10, y: rect.minY + h * 0.26))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.16, y: rect.maxY - h * 0.10))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.16, y: rect.maxY - h * 0.10))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.10, y: rect.minY + h * 0.26))
        p.closeSubpath()
        return p
    }
}
struct CharmGearGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.10))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.18, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.10))
        p.addLine(to: CGPoint(x: rect.minX + w * 0.18, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Reusable star rating + bar

struct StarRatingView: View {
    let earned: Int
    let total: Int
    var size: CGFloat = 14
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { i in
                StarShape()
                    .fill(i < earned ? GQBTheme.gold : GQBTheme.goldDeep.opacity(0.5))
                    .frame(width: size, height: size)
            }
        }
    }
}

struct StatBar: View {
    let value: Int
    let maxValue: Int
    let color: Color
    var height: CGFloat = 14
    var body: some View {
        GeometryReader { geo in
            let frac = maxValue > 0 ? max(0, min(1, CGFloat(value) / CGFloat(maxValue))) : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.35))
                Capsule().fill(
                    LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                ).frame(width: geo.size.width * frac)
            }
        }
        .frame(height: height)
    }
}
