import SwiftUI
import Charts

struct RecipeDetailView: View {
    @Environment(RecipeStore.self) private var store
    let recipe: Recipe

    private var level: Int { store.level(of: recipe) }

    private var levelBinding: Binding<Double> {
        Binding(
            get: { Double(store.level(of: recipe)) },
            set: { store.setLevel(Int($0.rounded()), for: recipe) }
        )
    }

    var body: some View {
        List {
            header

            Section("必要な食材") {
                ForEach(recipe.ingredients, id: \.id) { item in
                    if let ing = store.ingredient(item.id) {
                        HStack {
                            Text(ing.emoji).font(.title2).frame(width: 36)
                            VStack(alignment: .leading) {
                                Text(ing.name)
                                Text("1個 \(ing.energy) エナジー")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("×\(item.count)")
                                .font(.title3.bold().monospacedDigit())
                        }
                    }
                }
                LabeledContent("合計") {
                    Text("\(recipe.totalCount)個").bold().monospacedDigit()
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Lv\(level)")
                            .font(.title2.bold().monospacedDigit())
                        Spacer()
                        Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                        Text(store.energy(of: recipe, level: level).formatted())
                            .font(.largeTitle.bold().monospacedDigit())
                            .contentTransition(.numericText())
                    }
                    HStack {
                        Button { store.setLevel(level - 1, for: recipe) } label: {
                            Image(systemName: "minus.circle.fill").font(.title2)
                        }
                        .disabled(level <= 1)
                        Slider(value: levelBinding, in: 1...Double(RecipeLevel.max), step: 1)
                        Button { store.setLevel(level + 1, for: recipe) } label: {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                        .disabled(level >= RecipeLevel.max)
                    }
                    .buttonStyle(.borderless)
                    .animation(.snappy, value: level)
                }
                .padding(.vertical, 4)

                energyChart
                    .frame(height: 160)
                    .padding(.vertical, 4)
            } header: {
                Text("レシピレベルとエナジー")
            } footer: {
                Text("エナジー = 食材エナジー合計 × レシピボーナス × レベル倍率。フィールドボーナスや大成功、イベント補正は含みません。設定したレベルは保存されます。")
            }

            Section("内訳") {
                LabeledContent("食材エナジー合計", value: store.ingredientEnergy(of: recipe).formatted())
                LabeledContent("レシピボーナス", value: String(format: "×%.2f（+%g%%）", recipe.bonusMultiplier, recipe.bonusPercent))
                LabeledContent("Lv\(level) 倍率", value: String(format: "×%.2f", RecipeLevel.multiplier(level)))
                LabeledContent("Lv1 / Lv\(RecipeLevel.max)",
                               value: "\(store.energy(of: recipe, level: 1).formatted()) / \(store.energy(of: recipe, level: RecipeLevel.max).formatted())")
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                store.toggleFavorite(recipe)
            } label: {
                Image(systemName: store.isFavorite(recipe) ? "star.fill" : "star")
                    .foregroundStyle(.yellow)
            }
            .accessibilityLabel(store.isFavorite(recipe) ? "お気に入りから外す" : "お気に入りに追加")
        }
        .tint(recipe.category.tint)
    }

    private var header: some View {
        Section {
            VStack(spacing: 10) {
                DishIllustration(recipe: recipe, size: 180)
                Text(recipe.name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text(recipe.nameEn)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    tag(recipe.category.title)
                    tag("鍋 \(recipe.totalCount)個〜")
                    tag(String(format: "ボーナス ×%.2f", recipe.bonusMultiplier))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.clear)
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(recipe.category.tint.opacity(0.15), in: .capsule)
            .foregroundStyle(recipe.category.tint)
    }

    private var energyChart: some View {
        Chart {
            ForEach(Array(stride(from: 1, through: RecipeLevel.max, by: 1)), id: \.self) { lv in
                LineMark(x: .value("Lv", lv), y: .value("エナジー", store.energy(of: recipe, level: lv)))
                    .foregroundStyle(recipe.category.tint)
            }
            PointMark(x: .value("Lv", level), y: .value("エナジー", store.energy(of: recipe, level: level)))
                .foregroundStyle(recipe.category.tint)
                .symbolSize(80)
        }
        .chartXScale(domain: 1...RecipeLevel.max)
        .chartXAxis {
            AxisMarks(values: [1, 10, 20, 30, 40, 50, 60, 70])
        }
    }
}
