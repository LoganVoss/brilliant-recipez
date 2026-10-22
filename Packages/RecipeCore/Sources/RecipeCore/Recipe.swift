import Foundation

public struct RecipeIngredient: Identifiable, Codable, Equatable, Sendable {
    public var name: String
    public var amount: String
    public var id: String { name }

    public init(name: String, amount: String) {
        self.name = name
        self.amount = amount
    }
}

public struct Recipe: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var summary: String
    public var cuisine: String
    public var minutes: Int
    public var servings: Int
    public var ingredients: [RecipeIngredient]
    public var steps: [String]
    public var isDemo: Bool
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        cuisine: String,
        minutes: Int,
        servings: Int,
        ingredients: [RecipeIngredient],
        steps: [String],
        isDemo: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.cuisine = cuisine
        self.minutes = minutes
        self.servings = servings
        self.ingredients = ingredients
        self.steps = steps
        self.isDemo = isDemo
        self.createdAt = createdAt
    }

    /// A completely offline example, clearly distinguished from a generated recipe.
    public static let demo = Recipe(
        id: UUID(uuidString: "0AB6D604-2C1E-477E-B020-5C1AA1DD7F2F")!,
        title: "Chickpea and spinach bowls",
        summary: "Chickpeas, tomatoes, and spinach cooked in one pan with lemon.",
        cuisine: "Mediterranean inspired",
        minutes: 20,
        servings: 2,
        ingredients: [
            RecipeIngredient(name: "Chickpeas", amount: "1 can (15 oz), drained and rinsed"),
            RecipeIngredient(name: "Tomatoes", amount: "2 medium, chopped"),
            RecipeIngredient(name: "Spinach", amount: "3 packed cups"),
            RecipeIngredient(name: "Lemon", amount: "½, juiced"),
            RecipeIngredient(name: "Olive oil", amount: "1 tablespoon"),
            RecipeIngredient(name: "Salt", amount: "¼ teaspoon, or to taste"),
            RecipeIngredient(name: "Black pepper", amount: "⅛ teaspoon, or to taste")
        ],
        steps: [
            "Warm the olive oil in a large skillet over medium heat. Add the tomatoes and cook for 5 minutes, stirring occasionally, until they begin to soften.",
            "Add the drained chickpeas, salt, and black pepper. Cook for 5 minutes, stirring occasionally, until heated through.",
            "Fold in the spinach a handful at a time. Cook for 2–3 minutes, until wilted.",
            "Remove from the heat and stir in the lemon juice. Divide between two bowls and serve warm."
        ],
        isDemo: true,
        createdAt: Date(timeIntervalSince1970: 0)
    )
}

public struct RecipePreferences: Equatable, Sendable {
    public var servings: Int
    public var maximumMinutes: Int
    public var direction: String
    public var includeStaples: Bool

    public init(
        servings: Int = 2,
        maximumMinutes: Int = 30,
        direction: String = "Any style",
        includeStaples: Bool = true
    ) {
        self.servings = servings
        self.maximumMinutes = maximumMinutes
        self.direction = direction
        self.includeStaples = includeStaples
    }
}

public enum IngredientNormalizer {
    /// Produces stable, editable display names without reinterpreting the user's food choices.
    public static func normalize(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.compactMap { name in
            let cleaned = name
                .split(whereSeparator: { $0.isWhitespace })
                .joined(separator: " ")
                .trimmingCharacters(in: CharacterSet(charactersIn: ",;."))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard !cleaned.isEmpty, seen.insert(cleaned).inserted else { return nil }
            return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        }
    }
}
