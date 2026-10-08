import Foundation
import Observation

@Observable
final class RecipeStore {
    let dataVersion: String
    let ingredients: [Ingredient]
    let recipes: [Recipe]
    private let ingredientByID: [String: Ingredient]

    /// お気に入りのレシピID
    var favorites: Set<String> { didSet { save() } }
    /// ゲーム内での各レシピのレベル（未設定は Lv1）
    var levels: [String: Int] { didSet { save() } }

    private let defaults = UserDefaults.standard
    private enum Key {
        static let favorites = "favorites"
        static let levels = "recipeLevels"
    }

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "recipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(RecipeData.self, from: data)
        else {
            fatalError("recipes.json を読み込めませんでした")
        }
        dataVersion = decoded.dataVersion
        ingredients = decoded.ingredients
        recipes = decoded.recipes
        ingredientByID = Dictionary(uniqueKeysWithValues: decoded.ingredients.map { ($0.id, $0) })
        favorites = Set(defaults.stringArray(forKey: Key.favorites) ?? [])
        levels = (defaults.dictionary(forKey: Key.levels) as? [String: Int]) ?? [:]
    }

    private func save() {
        defaults.set(Array(favorites), forKey: Key.favorites)
        defaults.set(levels, forKey: Key.levels)
    }

    // MARK: - 参照

    func ingredient(_ id: String) -> Ingredient? { ingredientByID[id] }

    func level(of recipe: Recipe) -> Int { levels[recipe.id] ?? 1 }

    func setLevel(_ level: Int, for recipe: Recipe) {
        levels[recipe.id] = min(max(level, 1), RecipeLevel.max)
    }

    func isFavorite(_ recipe: Recipe) -> Bool { favorites.contains(recipe.id) }

    func toggleFavorite(_ recipe: Recipe) {
        if favorites.contains(recipe.id) { favorites.remove(recipe.id) } else { favorites.insert(recipe.id) }
    }

    // MARK: - エナジー計算

    /// 食材そのもののエナジー合計（ボーナス・レベル補正なし）
    func ingredientEnergy(of recipe: Recipe) -> Int {
        recipe.ingredients.reduce(0) { sum, item in
            sum + (ingredientByID[item.id]?.energy ?? 0) * item.count
        }
    }

    /// 料理のエナジー = 食材エナジー合計 × レシピボーナス × レシピレベル倍率
    /// （フィールドボーナス・料理のイベント補正・大成功は含まない）
    func energy(of recipe: Recipe, level: Int) -> Int {
        let base = Double(ingredientEnergy(of: recipe))
        return Int((base * recipe.bonusMultiplier * RecipeLevel.multiplier(level)).rounded())
    }

    func currentEnergy(of recipe: Recipe) -> Int { energy(of: recipe, level: level(of: recipe)) }
}
