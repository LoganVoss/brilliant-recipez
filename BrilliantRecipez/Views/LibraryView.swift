import SwiftUI
import RecipeCore

struct LibraryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var search = ""
    @State private var pendingRemoval: Recipe?
    private var recipes: [Recipe] {
        model.savedRecipes.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.ingredients.contains { $0.name.localizedCaseInsensitiveContains(search) } }
    }
    var body: some View {
        NavigationStack {
            Group {
                if model.savedRecipes.isEmpty {
                    ContentUnavailableView {
                        Label("No saved recipes", systemImage: "bookmark")
                    } description: { Text("Save a recipe to find it here.") }
                    actions: { Button("View sample recipe") { model.presentedRecipe = .demo }.buttonStyle(.borderedProminent) }
                } else if recipes.isEmpty {
                    ContentUnavailableView.search(text: search)
                } else {
                    List {
                        Section {
                            ForEach(recipes) { recipe in
                                Button { model.presentedRecipe = recipe } label: {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 15).fill(Theme.cream)
                                            if recipe.isDemo { BowlArtwork().padding(6) }
                                            else { Image(systemName: "fork.knife").font(.title2).foregroundStyle(Theme.brass) }
                                        }.frame(width: 72, height: 72)
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(recipe.title).font(.system(.headline, design: .serif)).foregroundStyle(.primary)
                                            Text("\(recipe.minutes) min · \(recipe.servings) servings").font(.caption).foregroundStyle(.secondary)
                                            if recipe.isDemo { Text("SAMPLE RECIPE").font(.system(size: 9, weight: .bold)).tracking(1).foregroundStyle(.secondary) }
                                        }
                                    }.padding(.vertical, 8)
                                }.accessibilityIdentifier("savedRecipeRow")
                                    .swipeActions { Button("Remove", role: .destructive) { pendingRemoval = recipe } }
                            }
                        } header: { Text("\(model.savedRecipes.count) \(model.savedRecipes.count == 1 ? "recipe" : "recipes")") }
                    }.listStyle(.insetGrouped).scrollContentBackground(.hidden)
                }
            }.navigationTitle("Saved recipes").background(Theme.cream)
                .searchable(text: $search, prompt: "Find a recipe or ingredient")
                .confirmationDialog("Remove this saved recipe?", isPresented: Binding(get: { pendingRemoval != nil }, set: { if !$0 { pendingRemoval = nil } }), titleVisibility: .visible) {
                    Button("Remove recipe", role: .destructive) { if let recipe = pendingRemoval { model.toggleSave(recipe) }; pendingRemoval = nil }
                }
        }
    }
}
