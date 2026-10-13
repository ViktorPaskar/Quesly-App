import SwiftUI

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(Angle.degrees(Double(i) * 60 - 90).radians)
            let p = CGPoint(x: c.x + r * cos(angle), y: c.y + r * sin(angle))
            if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }
}

/// Hexagon medal used for user badges and achievements.
struct HexBadge: View {
    var color: Color
    var icon: QIcon
    var isLocked = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let tint = isLocked ? Color(hex: 0xC8C8C8) : color
            ZStack {
                Hexagon().fill(tint)
                Icon(icon, size: s * 0.42)
                    .foregroundStyle(.white.opacity(isLocked ? 0.9 : 1))
            }
            .frame(width: s, height: s)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
