import SwiftUI
import UIKit

/// 料理のイラスト。
/// Assets に「レシピID」と同じ名前の画像（例: NINJA_CURRY）があればそれを表示し、
/// なければカテゴリの器 + 食材で自動生成したイラストを表示する。
struct DishIllustration: View {
    @Environment(RecipeStore.self) private var store
    let recipe: Recipe
    var size: CGFloat = 56

    var body: some View {
        Group {
            if UIImage(named: recipe.id) != nil {
                Image(recipe.id)
                    .resizable()
                    .scaledToFill()
            } else {
                GeneratedDish(recipe: recipe, emojis: plating, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.22))
        .accessibilityLabel("\(recipe.name)のイラスト")
    }

    /// 盛り付ける食材の絵文字。使う個数が多い食材ほど多く乗せる（最大7個）
    private var plating: [String] {
        let total = max(recipe.totalCount, 1)
        let slots = min(7, max(3, recipe.ingredients.count + 2))
        var result: [String] = []
        for item in recipe.ingredients.sorted(by: { $0.count > $1.count }) {
            guard let ing = store.ingredient(item.id) else { continue }
            let n = max(1, Int((Double(item.count) / Double(total) * Double(slots)).rounded()))
            result += Array(repeating: ing.emoji, count: n)
        }
        // 食材の種類が交互に並ぶように混ぜる
        return Array(interleave(result).prefix(slots))
    }

    private func interleave(_ items: [String]) -> [String] {
        var buckets: [String: Int] = [:]
        var order: [String] = []
        for e in items {
            if buckets[e] == nil { order.append(e) }
            buckets[e, default: 0] += 1
        }
        var out: [String] = []
        while out.count < items.count {
            for e in order where (buckets[e] ?? 0) > 0 {
                out.append(e)
                buckets[e]! -= 1
            }
        }
        return out
    }
}

// MARK: - 自動生成イラスト

private struct GeneratedDish: View {
    let recipe: Recipe
    let emojis: [String]
    let size: CGFloat

    /// レシピIDから決まる疑似乱数（毎回同じ盛り付けになる）
    private var seed: Int { recipe.id.unicodeScalars.reduce(7) { ($0 &* 31 &+ Int($1.value)) & 0xFFFF } }

    var body: some View {
        ZStack {
            background
            vessel
            toppings
        }
        .frame(width: size, height: size)
    }

    private var background: some View {
        LinearGradient(colors: [recipe.category.tint.opacity(0.25), recipe.category.tint.opacity(0.08)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    @ViewBuilder
    private var vessel: some View {
        let s = size
        switch recipe.category {
        case .curry:
            ZStack {
                // お皿
                Ellipse().fill(.white)
                    .frame(width: s * 0.92, height: s * 0.62)
                    .overlay(Ellipse().stroke(Color.black.opacity(0.08), lineWidth: s * 0.02))
                    .shadow(color: .black.opacity(0.12), radius: s * 0.03, y: s * 0.02)
                // ごはん
                Ellipse().fill(Color(red: 1, green: 0.99, blue: 0.95))
                    .frame(width: s * 0.38, height: s * 0.30)
                    .offset(x: -s * 0.18, y: -s * 0.02)
                // ルー
                Ellipse().fill(curryColor.gradient)
                    .frame(width: s * 0.56, height: s * 0.36)
                    .offset(x: s * 0.08, y: s * 0.05)
            }
            .offset(y: s * 0.08)

        case .salad:
            ZStack {
                // 葉っぱ
                ForEach(0..<6, id: \.self) { i in
                    Circle().fill(Color.green.opacity(0.55 + Double(i % 3) * 0.12))
                        .frame(width: s * 0.26, height: s * 0.26)
                        .offset(x: s * (-0.28 + Double(i) * 0.11), y: -s * (0.02 + Double(i % 2) * 0.06))
                }
                // ボウル
                Bowl().fill(Color(red: 0.95, green: 0.97, blue: 0.93).gradient)
                    .frame(width: s * 0.86, height: s * 0.42)
                    .overlay(Bowl().stroke(Color.black.opacity(0.08), lineWidth: s * 0.02))
                    .offset(y: s * 0.2)
                    .shadow(color: .black.opacity(0.12), radius: s * 0.03, y: s * 0.02)
            }
            .offset(y: s * 0.04)

        case .dessert:
            ZStack {
                // お皿
                Ellipse().fill(.white)
                    .frame(width: s * 0.86, height: s * 0.36)
                    .overlay(Ellipse().stroke(Color.black.opacity(0.08), lineWidth: s * 0.02))
                    .offset(y: s * 0.22)
                    .shadow(color: .black.opacity(0.12), radius: s * 0.03, y: s * 0.02)
                // クリーム
                RoundedRectangle(cornerRadius: s * 0.16)
                    .fill(LinearGradient(colors: [Color(red: 1, green: 0.93, blue: 0.95), Color(red: 1, green: 0.82, blue: 0.87)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: s * 0.6, height: s * 0.42)
                    .offset(y: s * 0.04)
            }
        }
    }

    /// 食材の色合いでルーの色を少し変える
    private var curryColor: Color {
        let ids = Set(recipe.ingredients.map(\.id))
        if ids.contains("MOOMOO_MILK") && !ids.contains("FIERY_HERB") { return Color(red: 0.96, green: 0.90, blue: 0.78) }
        if ids.contains("FIERY_HERB") { return Color(red: 0.80, green: 0.36, blue: 0.16) }
        if ids.contains("GLOSSY_AVOCADO") { return Color(red: 0.62, green: 0.70, blue: 0.32) }
        return Color(red: 0.78, green: 0.50, blue: 0.18)
    }

    private var toppings: some View {
        let positions = layout(for: recipe.category)
        return ZStack {
            ForEach(Array(emojis.enumerated()), id: \.offset) { i, emoji in
                let p = positions[i % positions.count]
                let tilt = Double((seed >> (i % 8)) % 41) - 20
                Text(emoji)
                    .font(.system(size: size * 0.2))
                    .rotationEffect(.degrees(tilt))
                    .offset(x: p.x * size, y: p.y * size)
            }
        }
    }

    /// 器ごとの盛り付け位置（サイズに対する比率）
    private func layout(for category: RecipeCategory) -> [CGPoint] {
        switch category {
        case .curry:
            [CGPoint(x: 0.10, y: 0.10), CGPoint(x: 0.26, y: 0.16), CGPoint(x: -0.04, y: 0.20),
             CGPoint(x: 0.22, y: 0.02), CGPoint(x: 0.04, y: -0.01), CGPoint(x: 0.34, y: 0.08), CGPoint(x: -0.16, y: 0.16)]
        case .salad:
            [CGPoint(x: 0.0, y: -0.04), CGPoint(x: -0.2, y: 0.0), CGPoint(x: 0.2, y: -0.02),
             CGPoint(x: -0.1, y: -0.16), CGPoint(x: 0.12, y: -0.16), CGPoint(x: -0.28, y: -0.12), CGPoint(x: 0.28, y: -0.12)]
        case .dessert:
            [CGPoint(x: 0.0, y: -0.12), CGPoint(x: -0.16, y: -0.06), CGPoint(x: 0.16, y: -0.06),
             CGPoint(x: -0.08, y: 0.08), CGPoint(x: 0.1, y: 0.08), CGPoint(x: -0.26, y: 0.18), CGPoint(x: 0.26, y: 0.18)]
        }
    }
}

/// サラダボウル（下半分の円）
private struct Bowl: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                       control: CGPoint(x: rect.midX, y: 2 * rect.maxY - rect.minY))
        p.closeSubpath()
        return p
    }
}
