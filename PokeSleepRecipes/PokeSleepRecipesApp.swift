import SwiftUI

@main
struct PokeSleepRecipesApp: App {
    @State private var store = RecipeStore()

    var body: some Scene {
        WindowGroup {
            RecipeListView()
                .environment(store)
        }
    }
}
