import SwiftUI

enum RecipeSort: String, CaseIterable, Identifiable {
    case book = "図鑑順"
    case energy = "エナジー順"
    case count = "食材数順"
    case name = "名前順"
    var id: String { rawValue }
}

struct RecipeListView: View {
    @Environment(RecipeStore.self) private var store

    @State private var category: RecipeCategory = .curry
    @State private var searchText = ""
    @State private var sort: RecipeSort = .book
    @State private var favoritesOnly = false
    @State private var selectedIngredients: Set<String> = []
    @State private var showingFilter = false

    @AppStorage("potCapacity") private var potCapacity = 15
    @AppStorage("limitToPot") private var limitToPot = false

    private var filtered: [Recipe] {
        var list = store.recipes.filter { $0.category == category }

        if !searchText.isEmpty {
            list = list.filter { recipe in
                recipe.name.localizedStandardContains(searchText)
                    || recipe.nameEn.localizedStandardContains(searchText)
                    || recipe.ingredients.contains { store.ingredient($0.id)?.name.localizedStandardContains(searchText) == true }
            }
        }
        if favoritesOnly {
            list = list.filter { store.isFavorite($0) }
        }
        if !selectedIngredients.isEmpty {
            list = list.filter { recipe in
                selectedIngredients.isSubset(of: Set(recipe.ingredients.map(\.id)))
            }
        }
        if limitToPot {
            list = list.filter { $0.totalCount <= potCapacity }
        }

        switch sort {
        case .book: break
        case .energy: list.sort { store.currentEnergy(of: $0) > store.currentEnergy(of: $1) }
        case .count: list.sort { $0.totalCount > $1.totalCount }
        case .name: list.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        return list
    }

    private var activeFilterCount: Int {
        selectedIngredients.count + (limitToPot ? 1 : 0) + (favoritesOnly ? 1 : 0)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(RecipeCategory.allCases) { c in
                            Text(c.shortTitle).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if activeFilterCount > 0 {
                    Section {
                        ActiveFilterBar(
                            selectedIngredients: $selectedIngredients,
                            limitToPot: $limitToPot,
                            potCapacity: potCapacity,
                            favoritesOnly: $favoritesOnly
                        )
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }

                Section {
                    if filtered.isEmpty {
                        ContentUnavailableView("該当するレシピがありません",
                                               systemImage: "fork.knife",
                                               description: Text("条件をゆるめてみてください"))
                    }
                    ForEach(filtered) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeRow(recipe: recipe)
                        }
                    }
                } header: {
                    Text("\(category.title)  \(filtered.count)品")
                }
            }
            .navigationTitle("料理図鑑")
            .navigationDestination(for: Recipe.self) { RecipeDetailView(recipe: $0) }
            .searchable(text: $searchText, prompt: "料理名・食材名で検索")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        favoritesOnly.toggle()
                    } label: {
                        Image(systemName: favoritesOnly ? "star.fill" : "star")
                    }
                    .tint(.yellow)
                    .accessibilityLabel("お気に入りのみ")
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Picker("並び替え", selection: $sort) {
                            ForEach(RecipeSort.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                    Button {
                        showingFilter = true
                    } label: {
                        Image(systemName: activeFilterCount > 0
                              ? "line.3.horizontal.decrease.circle.fill"
                              : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("絞り込み")
                }
            }
            .sheet(isPresented: $showingFilter) {
                FilterSheet(selectedIngredients: $selectedIngredients,
                            potCapacity: $potCapacity,
                            limitToPot: $limitToPot)
            }
            .tint(category.tint)
        }
    }
}

// MARK: - 行

struct RecipeRow: View {
    @Environment(RecipeStore.self) private var store
    let recipe: Recipe

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            DishIllustration(recipe: recipe, size: 56)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(recipe.name).font(.headline).lineLimit(1)
                    if store.isFavorite(recipe) {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                    }
                }
                IngredientChips(recipe: recipe)
                HStack(spacing: 10) {
                    Label("\(recipe.totalCount)個", systemImage: "frying.pan")
                    Label("Lv\(store.level(of: recipe))  \(store.currentEnergy(of: recipe).formatted())", systemImage: "bolt.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

/// 食材を「🍎×7」の形で横並びに表示
struct IngredientChips: View {
    @Environment(RecipeStore.self) private var store
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 8) {
            ForEach(recipe.ingredients, id: \.id) { item in
                if let ing = store.ingredient(item.id) {
                    Text("\(ing.emoji)×\(item.count)")
                        .font(.subheadline.monospacedDigit())
                        .accessibilityLabel("\(ing.name) \(item.count)個")
                }
            }
        }
    }
}

// MARK: - 適用中の絞り込み

struct ActiveFilterBar: View {
    @Environment(RecipeStore.self) private var store
    @Binding var selectedIngredients: Set<String>
    @Binding var limitToPot: Bool
    let potCapacity: Int
    @Binding var favoritesOnly: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if favoritesOnly {
                    chip("★ お気に入り") { favoritesOnly = false }
                }
                if limitToPot {
                    chip("鍋 \(potCapacity)個以内") { limitToPot = false }
                }
                ForEach(store.ingredients.filter { selectedIngredients.contains($0.id) }) { ing in
                    chip("\(ing.emoji) \(ing.name)") { selectedIngredients.remove(ing.id) }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func chip(_ title: String, remove: @escaping () -> Void) -> some View {
        Button(action: remove) {
            HStack(spacing: 4) {
                Text(title)
                Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
