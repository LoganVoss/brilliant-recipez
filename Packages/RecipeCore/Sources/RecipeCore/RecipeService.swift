import Foundation

/// A generation boundary independent of any model framework or network provider.
public protocol RecipeService: Sendable {
    func generateRecipe(ingredients: [String], preferences: RecipePreferences) async throws -> Recipe
}

public enum RecipeServiceError: Error, Equatable, Sendable, LocalizedError {
    case invalidIngredients
    case invalidPreferences
    case invalidResponse
    case unexpectedIngredients

    public var errorDescription: String? {
        switch self {
        case .invalidIngredients:
            "Add 1–30 ingredients, with no more than 80 characters per name."
        case .invalidPreferences:
            "Choose 1–12 servings, 5–180 minutes, and a meal preference under 300 characters."
        case .invalidResponse:
            "The recipe was incomplete or did not match your choices. Try again."
        case .unexpectedIngredients:
            "The recipe used ingredients outside your list. Try again or update your ingredients."
        }
    }
}

/// Bounds and consistency checks shared by local generation and tests.
/// These checks do not certify cooking safety, allergens, or ingredients mentioned in prose.
public enum RecipeValidation {
    public static let optionalStaples = ["Water", "Salt", "Black pepper", "Olive oil"]

    public static func reviewedIngredients(_ names: [String], preferences: RecipePreferences) throws -> [String] {
        let reviewed = IngredientNormalizer.normalize(names)
        guard !reviewed.isEmpty, reviewed.count <= 30,
              reviewed.allSatisfy({ validText($0, maximum: 80) }) else {
            throw RecipeServiceError.invalidIngredients
        }
        guard (1...12).contains(preferences.servings),
              (5...180).contains(preferences.maximumMinutes),
              preferences.direction.count <= 300,
              !preferences.direction.unicodeScalars.contains(where: { CharacterSet.controlCharacters.subtracting(.newlines).contains($0) }) else {
            throw RecipeServiceError.invalidPreferences
        }
        return reviewed
    }

    public static func allowedIngredients(reviewed: [String], preferences: RecipePreferences) -> [String] {
        IngredientNormalizer.normalize(reviewed + (preferences.includeStaples ? optionalStaples : []))
    }

    /// Rejects incomplete generations and unknown or duplicated ingredient names.
    /// Preserves identifiers and dates so existing saved recipes remain compatible.
    public static func validated(_ recipe: Recipe, reviewed: [String], preferences: RecipePreferences) throws -> Recipe {
        let reviewed = try reviewedIngredients(reviewed, preferences: preferences)
        let allowed = allowedIngredients(reviewed: reviewed, preferences: preferences)
        guard validText(recipe.title, maximum: 120),
              validText(recipe.summary, maximum: 600),
              validText(recipe.cuisine, maximum: 80),
              (1...preferences.maximumMinutes).contains(recipe.minutes),
              recipe.servings == preferences.servings,
              !recipe.ingredients.isEmpty, recipe.ingredients.count <= 34,
              recipe.ingredients.allSatisfy({ validText($0.name, maximum: 80) && validText($0.amount, maximum: 160) }),
              (1...12).contains(recipe.steps.count),
              recipe.steps.allSatisfy({ validText($0, maximum: 1_500) }) else {
            throw RecipeServiceError.invalidResponse
        }
        let names = IngredientNormalizer.normalize(recipe.ingredients.map(\.name))
        guard names.count == recipe.ingredients.count else { throw RecipeServiceError.invalidResponse }
        guard Set(names).isSubset(of: Set(allowed)), !Set(names).isDisjoint(with: Set(reviewed)) else {
            throw RecipeServiceError.unexpectedIngredients
        }
        var result = recipe
        result.title = recipe.title.trimmingCharacters(in: .whitespacesAndNewlines)
        result.summary = recipe.summary.trimmingCharacters(in: .whitespacesAndNewlines)
        result.cuisine = recipe.cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
        result.ingredients = zip(names, recipe.ingredients).map { name, ingredient in
            RecipeIngredient(name: name, amount: ingredient.amount.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        result.steps = recipe.steps.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return result
    }

    private static func validText(_ text: String, maximum: Int) -> Bool {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !value.isEmpty && value.count <= maximum && !value.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
    }
}
