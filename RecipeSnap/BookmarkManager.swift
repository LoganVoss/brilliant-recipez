import Foundation
class BookmarkManager: ObservableObject {
    @Published var bookmarkedRecipes: [Recipe] = []
    private let bookmarkKey = "BookmarkedRecipes"

    init() {
        loadBookmarks()
    }

    func addRecipe(_ recipe: Recipe) {
        if !bookmarkedRecipes.contains(where: { $0.id == recipe.id }) {
            let timestampedRecipe = Recipe(
                id: recipe.id,
                title: recipe.title,
                description: recipe.description,
                ingredients: recipe.ingredients,
                instructions: recipe.instructions,
                imageBase64: recipe.imageBase64,
                createdAt: Date()
            )
            bookmarkedRecipes.insert(timestampedRecipe, at: 0)
            saveBookmarks()
        }
    }

    func removeRecipe(_ recipe: Recipe) {
        bookmarkedRecipes.removeAll { $0.id == recipe.id }
        saveBookmarks()
    }

    func isBookmarked(_ recipe: Recipe) -> Bool {
        bookmarkedRecipes.contains { $0.id == recipe.id }
    }

    private func saveBookmarks() {
        if let data = try? JSONEncoder().encode(bookmarkedRecipes) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        }
    }

    private func loadBookmarks() {
        if let data = UserDefaults.standard.data(forKey: bookmarkKey),
           let recipes = try? JSONDecoder().decode([Recipe].self, from: data) {
            bookmarkedRecipes = recipes.sorted { (recipe1, recipe2) -> Bool in
                let date1 = recipe1.createdAt ?? .distantPast
                let date2 = recipe2.createdAt ?? .distantPast
                return date1 > date2
            }
        }
    }
}
