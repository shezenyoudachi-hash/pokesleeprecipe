import SwiftUI

// MARK: - 料理カテゴリ

enum RecipeCategory: String, Codable, CaseIterable, Identifiable {
    case curry, salad, dessert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .curry: "カレー・シチュー"
        case .salad: "サラダ"
        case .dessert: "デザート・ドリンク"
        }
    }

    var shortTitle: String {
        switch self {
        case .curry: "カレー"
        case .salad: "サラダ"
        case .dessert: "デザート"
        }
    }

    var symbol: String {
        switch self {
        case .curry: "flame.fill"
        case .salad: "leaf.fill"
        case .dessert: "cup.and.saucer.fill"
        }
    }

    var tint: Color {
        switch self {
        case .curry: .orange
        case .salad: .green
        case .dessert: .pink
        }
    }
}

// MARK: - 食材

struct Ingredient: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let emoji: String
    /// 食材1個あたりの基礎エナジー
    let energy: Int
}

// MARK: - レシピ

struct RecipeIngredient: Codable, Hashable {
    let id: String
    let count: Int
}

struct Recipe: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let nameEn: String
    let category: RecipeCategory
    /// レシピボーナス（%）。例: 48 → ×1.48
    let bonusPercent: Double
    let ingredients: [RecipeIngredient]

    /// 必要な食材の合計個数（＝必要な鍋の容量）
    var totalCount: Int { ingredients.reduce(0) { $0 + $1.count } }

    var bonusMultiplier: Double { 1 + bonusPercent / 100 }
}

// MARK: - データファイル

struct RecipeData: Codable {
    let dataVersion: String
    let ingredients: [Ingredient]
    let recipes: [Recipe]
}

// MARK: - レシピレベル

enum RecipeLevel {
    static let max = 70

    /// レシピレベルごとのエナジー倍率（Lv1〜70）
    static let multipliers: [Double] = [
        1.00, 1.02, 1.04, 1.06, 1.08, 1.09, 1.11, 1.13, 1.16, 1.18,
        1.19, 1.21, 1.23, 1.24, 1.26, 1.28, 1.30, 1.31, 1.33, 1.35,
        1.37, 1.40, 1.42, 1.45, 1.47, 1.50, 1.52, 1.55, 1.58, 1.61,
        1.64, 1.67, 1.70, 1.74, 1.77, 1.81, 1.84, 1.88, 1.92, 1.96,
        2.00, 2.04, 2.08, 2.13, 2.17, 2.22, 2.27, 2.32, 2.37, 2.42,
        2.48, 2.53, 2.59, 2.65, 2.71, 2.77, 2.83, 2.90, 2.97, 3.03,
        3.09, 3.15, 3.21, 3.27, 3.34, 3.39, 3.43, 3.48, 3.52, 3.58,
    ]

    static func multiplier(_ level: Int) -> Double {
        multipliers[Swift.max(1, Swift.min(level, max)) - 1]
    }
}
