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
    var symbol: String
    var isLocked = false

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let tint = isLocked ? Color(hex: 0xC8C8C8) : color
            ZStack {
                Hexagon()
                    .fill(LinearGradient(colors: [tint.opacity(0.75), tint], startPoint: .top, endPoint: .bottom))
                Hexagon()
                    .stroke(Color.white.opacity(0.55), lineWidth: max(1, s * 0.06))
                    .padding(s * 0.1)
                Image(systemName: symbol)
                    .font(.system(size: s * 0.36, weight: .bold))
                    .foregroundStyle(.white.opacity(isLocked ? 0.9 : 1))
            }
            .frame(width: s, height: s)
            .shadow(color: tint.opacity(0.35), radius: s * 0.06, y: s * 0.04)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
