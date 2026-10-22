import Foundation
import XCTest
@testable import RecipeCore

final class RecipeCoreTests: XCTestCase {
    private let reviewed = ["Tomatoes", "Chickpeas"]

    func testNormalizerCleansWhitespaceCaseAndDuplicates() {
        XCTAssertEqual(
            IngredientNormalizer.normalize([" TOMATOES ", "tomatoes", "baby\n  SPINACH", "", "  ", "Lemon."]),
            ["Tomatoes", "Baby spinach", "Lemon"]
        )
    }

    func testSavedRecipeFormatStillRoundTrips() throws {
        let recipe = Recipe.demo
        let data = try JSONEncoder().encode(recipe)
        XCTAssertEqual(try JSONDecoder().decode(Recipe.self, from: data), recipe)
        XCTAssertTrue(recipe.isDemo)
        XCTAssertFalse(recipe.steps.isEmpty)
        XCTAssertEqual(recipe.ingredients.count, Set(recipe.ingredients.map(\.id)).count)
    }

    func testLegacySavedRecipeDecodesWithoutAnyProviderMetadata() throws {
        let data = Data(#"{"id":"0AB6D604-2C1E-477E-B020-5C1AA1DD7F2F","title":"Saved recipe","summary":"A saved meal.","cuisine":"Home cooking","minutes":20,"servings":2,"ingredients":[{"name":"Tomatoes","amount":"2"}],"steps":["Chop and serve."],"isDemo":false,"createdAt":0}"#.utf8)
        let recipe = try JSONDecoder().decode(Recipe.self, from: data)
        XCTAssertEqual(recipe.title, "Saved recipe")
        XCTAssertFalse(recipe.isDemo)
        XCTAssertEqual(recipe.createdAt, Date(timeIntervalSinceReferenceDate: 0))
    }

    func testInputIsNormalizedBeforeItReachesTheModel() throws {
        XCTAssertEqual(
            try RecipeValidation.reviewedIngredients([" tomatoes ", "Tomatoes", "CHICKPEAS"], preferences: .init()),
            reviewed
        )
    }

    func testInputRejectsEmptyOversizedAndControlCharacterNames() {
        for input in [[], [" "], [String(repeating: "x", count: 81)], ["Tomato\u{0000}"], (0...30).map { "Ingredient \($0)" }] {
            assertError(.invalidIngredients) {
                try RecipeValidation.reviewedIngredients(input, preferences: .init())
            }
        }
    }

    func testPreferencesRejectUnusableBounds() {
        let cases = [
            RecipePreferences(servings: 0), RecipePreferences(servings: 13),
            RecipePreferences(maximumMinutes: 4), RecipePreferences(maximumMinutes: 181),
            RecipePreferences(direction: String(repeating: "x", count: 301)),
            RecipePreferences(direction: "Meal\u{0000}")
        ]
        for preferences in cases {
            assertError(.invalidPreferences) {
                try RecipeValidation.reviewedIngredients(reviewed, preferences: preferences)
            }
        }
    }

    func testPreferenceBoundariesAndMultilineFoodPreferencesAreAccepted() throws {
        for preferences in [RecipePreferences(servings: 1, maximumMinutes: 5), RecipePreferences(servings: 12, maximumMinutes: 180, direction: "Quick bowl\nMild spices")] {
            XCTAssertEqual(try RecipeValidation.reviewedIngredients(reviewed, preferences: preferences), reviewed)
        }
    }

    func testStaplesAreExplicitAndDeduplicated() {
        XCTAssertEqual(RecipeValidation.allowedIngredients(reviewed: ["Tomatoes", "Salt"], preferences: .init()),
                       ["Tomatoes", "Salt", "Water", "Black pepper", "Olive oil"])
        XCTAssertEqual(RecipeValidation.allowedIngredients(reviewed: reviewed, preferences: .init(includeStaples: false)), reviewed)
    }

    func testValidRecipeIsCleanedWithoutLosingIdentity() throws {
        var recipe = validRecipe()
        recipe.title = "  Tomato chickpea bowl  "
        recipe.ingredients[0].name = " tomatoes "
        recipe.ingredients[0].amount = " 2 medium "
        let result = try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init())
        XCTAssertEqual(result.title, "Tomato chickpea bowl")
        XCTAssertEqual(result.ingredients[0], RecipeIngredient(name: "Tomatoes", amount: "2 medium"))
        XCTAssertEqual(result.id, recipe.id)
        XCTAssertEqual(result.createdAt, recipe.createdAt)
        XCTAssertFalse(result.isDemo)
    }

    func testUnknownIngredientCannotReachRecipeView() {
        var recipe = validRecipe()
        recipe.ingredients[1].name = "Chicken"
        assertError(.unexpectedIngredients) {
            try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init())
        }
    }

    func testExtraIngredientReportsTheActionableIngredientError() {
        var recipe = validRecipe()
        recipe.ingredients = [RecipeIngredient(name: "Apple", amount: "1"), RecipeIngredient(name: "Toast", amount: "1 slice")]
        assertError(.unexpectedIngredients) {
            try RecipeValidation.validated(recipe, reviewed: ["Apple"], preferences: .init(includeStaples: false))
        }
    }

    func testStaplesCannotBeUsedWhenDisabled() throws {
        var recipe = validRecipe()
        recipe.ingredients[1].name = "Olive oil"
        XCTAssertNoThrow(try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init()))
        assertError(.unexpectedIngredients) {
            try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init(includeStaples: false))
        }
    }

    func testRecipeMustUseAtLeastOneReviewedIngredient() {
        var recipe = validRecipe()
        recipe.ingredients = [RecipeIngredient(name: "Salt", amount: "1 pinch")]
        assertError(.unexpectedIngredients) {
            try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init())
        }
    }

    func testDuplicateNamesAreRejectedAfterNormalization() {
        var recipe = validRecipe()
        recipe.ingredients[1].name = " tomatoes. "
        assertError(.invalidResponse) {
            try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init())
        }
    }

    func testIncompleteRecipesAreRejected() {
        let mutations: [(inout Recipe) -> Void] = [
            { $0.title = " " }, { $0.summary = "" }, { $0.cuisine = "" },
            { $0.ingredients = [] }, { $0.ingredients[0].amount = "" },
            { $0.steps = [] }, { $0.steps = [" "] },
            { $0.steps = Array(repeating: "Cook.", count: 13) },
            { $0.title = String(repeating: "x", count: 121) },
            { $0.steps = ["Cook\u{0000}"] }
        ]
        for mutate in mutations {
            var recipe = validRecipe()
            mutate(&recipe)
            assertError(.invalidResponse) {
                try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init())
            }
        }
    }

    func testRecipesMustMatchServingsAndTimeLimit() {
        let mutations: [(inout Recipe) -> Void] = [
            { $0.minutes = 0 }, { $0.minutes = 31 }, { $0.servings = 4 }
        ]
        for mutate in mutations {
            var recipe = validRecipe()
            mutate(&recipe)
            assertError(.invalidResponse) {
                try RecipeValidation.validated(recipe, reviewed: reviewed, preferences: .init())
            }
        }
    }

    private func validRecipe() -> Recipe {
        Recipe(title: "Tomato chickpea bowl", summary: "Chickpeas cooked with tomatoes.", cuisine: "Home cooking",
               minutes: 20, servings: 2,
               ingredients: [RecipeIngredient(name: "Tomatoes", amount: "2 medium"), RecipeIngredient(name: "Chickpeas", amount: "1 can")],
               steps: ["Cook the tomatoes and chickpeas in a nonstick pan until heated through."])
    }

    private func assertError<T>(_ expected: RecipeServiceError, file: StaticString = #filePath, line: UInt = #line, operation: () throws -> T) {
        do {
            _ = try operation()
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? RecipeServiceError, expected, file: file, line: line)
        }
    }
}
