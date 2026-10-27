import SwiftUI
import UIKit

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

/// Custom faceted 3D gem badge (`Assets/Badges/badge-<id>` & `badge-<id>-locked`).
struct HexBadge: View {
    var asset: String
    var color: Color = .qGreen
    var icon: QIcon = .starFill
    var isLocked: Bool = false

    init(asset: String, isLocked: Bool = false) {
        self.asset = asset
        self.isLocked = isLocked
    }

    init(tier: BadgeTier, isLocked: Bool = false) {
        self.asset = tier.assetName
        self.color = tier.color
        self.icon = tier.icon
        self.isLocked = isLocked
    }

    init(color: Color, icon: QIcon, isLocked: Bool = false, asset: String = "badge-first") {
        self.asset = asset
        self.color = color
        self.icon = icon
        self.isLocked = isLocked
    }

    private var resolvedAssetName: String {
        isLocked ? "\(asset)-locked" : asset
    }

    var body: some View {
        Group {
            if UIImage(named: resolvedAssetName) != nil {
                Image(resolvedAssetName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .shadow(color: isLocked ? .clear : Color.black.opacity(0.10), radius: 4, y: 2)
            } else {
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
            }
        }
        .accessibilityHidden(true)
    }
}
