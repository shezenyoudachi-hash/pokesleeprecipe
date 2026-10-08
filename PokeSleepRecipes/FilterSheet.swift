import SwiftUI

struct FilterSheet: View {
    @Environment(RecipeStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedIngredients: Set<String>
    @Binding var potCapacity: Int
    @Binding var limitToPot: Bool

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 8)]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("鍋に入るレシピだけ表示", isOn: $limitToPot)
                    Stepper(value: $potCapacity, in: 15...300) {
                        HStack {
                            Text("鍋の容量")
                            Spacer()
                            Text("\(potCapacity)個").monospacedDigit().foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("鍋の容量")
                } footer: {
                    Text("必要な食材の合計数が鍋の容量以下のレシピだけを表示します。")
                }

                Section {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(store.ingredients) { ing in
                            let on = selectedIngredients.contains(ing.id)
                            Button {
                                if on { selectedIngredients.remove(ing.id) } else { selectedIngredients.insert(ing.id) }
                            } label: {
                                VStack(spacing: 2) {
                                    Text(ing.emoji).font(.title2)
                                    Text(ing.name).font(.caption2).lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(on ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08),
                                            in: .rect(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(on ? Color.accentColor : .clear, lineWidth: 2)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("食材で絞り込み")
                } footer: {
                    Text("選んだ食材をすべて使うレシピを表示します。")
                }
            }
            .navigationTitle("絞り込み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("リセット") {
                        selectedIngredients.removeAll()
                        limitToPot = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
